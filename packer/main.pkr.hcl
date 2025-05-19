# Define the AWS source for building the AMI
source "amazon-ebs" "ubuntu" {
  ami_name      = var.ami_name
  instance_type = var.instance_type
  region        = var.aws_region
  source_ami    = var.source_ami
  ssh_username  = var.ssh_username

  # Security group for the build instance
  vpc_filter {
    filters = {
      "isDefault" = "true"
    }
  }

  temporary_security_group_source_cidr = ["0.0.0.0/0"] # Allow SSH during build
  associate_public_ip_address         = true

  # Tags for the AMI
  ami_description = "Ubuntu 24.04 LTS with Nginx, Apache, Docker, Ansible, Terraform, Jenkins"
  tags = {
    Name        = "prod-ubuntu-24-04"
    Environment = "Production"
    BuiltBy     = "Packer"
  }
}

# Build block to define the provisioning steps
build {
  sources = ["source.amazon-ebs.ubuntu"]

  # Provisioning steps
  provisioner "shell" {
    inline = [
      "# Update and upgrade the system",
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",

      "# Install Nginx",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",

      "# Install Apache",
      "sudo apt-get install -y apache2",
      "sudo systemctl enable apache2",
      "sudo systemctl start apache2",

      "# Install Docker",
      "sudo apt-get install -y ca-certificates curl",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc",
      "sudo chmod a+r /etc/apt/keyrings/docker.asc",
      "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo usermod -aG docker ${var.ssh_username}",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",

      "# Install Ansible",
      "sudo apt-get install -y software-properties-common",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt-get install -y ansible",

      "# Install Terraform",
      "sudo apt-get install -y gnupg software-properties-common curl",
      "curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "echo 'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main' | sudo tee /etc/apt/sources.list.d/hashicorp.list",
      "sudo apt-get update -y",
      "sudo apt-get install -y terraform",

      "# Install Jenkins",
      "sudo apt-get install -y fontconfig openjdk-17-jre",
      "curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null",
      "echo 'deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
      "sudo apt-get update -y",
      "sudo apt-get install -y jenkins",
      "sudo systemctl enable jenkins",
      "sudo systemctl start jenkins",

      "# Configure security: Install and configure UFW (Uncomplicated Firewall)",
      "sudo apt-get install -y ufw",
      "sudo ufw default deny incoming",
      "sudo ufw default allow outgoing",
      "sudo ufw allow 22/tcp",   # SSH
      "sudo ufw allow 80/tcp",   # HTTP
      "sudo ufw allow 443/tcp",  # HTTPS
      "sudo ufw allow 8080/tcp", # Jenkins
      "sudo ufw enable",

      "# Harden SSH",
      "sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config",
      "sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config",
      "sudo systemctl restart sshd",

      "# Clean up",
      "sudo apt-get autoremove -y",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*"
    ]
  }

  # Upload the Packer manifest to S3
  post-processor "manifest" {
    output = "manifest.json"
  }

  post-processor "shell-local" {
    inline = [
      "aws s3 cp manifest.json s3://${var.s3_bucket}/manifests/manifest-${var.ami_name}.json"
    ]
  }
}
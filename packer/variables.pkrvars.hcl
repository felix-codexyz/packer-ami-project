aws_region     = "us-east-1"
instance_type  = "t3.large"
source_ami     = "ami-0a7620d611d3ceae4" # Replace with latest Ubuntu 24.04 LTS AMI ID
ssh_username   = "ubuntu"
ami_name       = "prod-ubuntu-24-04-ami-{{timestamp}}"
s3_bucket      = "packer-ami-store-aws-azure-gcp"
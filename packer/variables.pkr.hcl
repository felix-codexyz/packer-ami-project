variable "aws_region" {
  type        = string
  description = "AWS region to build the AMI"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for building the AMI"
}

variable "source_ami" {
  type        = string
  description = "Base Ubuntu AMI ID"
}

variable "ssh_username" {
  type        = string
  description = "Username for SSH access"
}

variable "ami_name" {
  type        = string
  description = "Name of the output AMI"
}

variable "s3_bucket" {
  type        = string
  description = "S3 bucket to store Packer manifest"
}
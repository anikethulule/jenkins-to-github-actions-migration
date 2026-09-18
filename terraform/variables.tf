variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "jenkins-ecr"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "vpc_id" {
  description = "VPC ID where EC2 will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where EC2 will be created"
  type        = string
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed to access SSH"
  type        = list(string)

  validation {
    condition     = length(var.allowed_ssh_cidr) > 0
    error_message = "At least one SSH CIDR must be provided."
  }
}

variable "allowed_web_cidr" {
  description = "CIDRs allowed to access web/application ports"
  type        = list(string)

  default = ["0.0.0.0/0"]
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "jenkins-app"
}
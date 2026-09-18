############################################################
# Data Sources
############################################################

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

############################################################
# ECR
############################################################

resource "aws_ecr_repository" "this" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 tagged images"

        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }

        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images after 7 days"

        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}

############################################################
# IAM Role for EC2
############################################################

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_power_user" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-instance-profile"

  role = aws_iam_role.ec2.name
}

############################################################
# Security Group
############################################################

resource "aws_security_group" "jenkins" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Security group for Jenkins EC2 instance"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-sg"
  }
}

############################################################
# SSH
############################################################

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = toset(var.allowed_ssh_cidr)

  security_group_id = aws_security_group.jenkins.id

  cidr_ipv4   = each.value
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22

  description = "SSH access"
}

############################################################
# HTTP
############################################################

resource "aws_vpc_security_group_ingress_rule" "http" {
  for_each = toset(var.allowed_web_cidr)

  security_group_id = aws_security_group.jenkins.id

  cidr_ipv4   = each.value
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80

  description = "HTTP access"
}

############################################################
# HTTPS
############################################################

resource "aws_vpc_security_group_ingress_rule" "https" {
  for_each = toset(var.allowed_web_cidr)

  security_group_id = aws_security_group.jenkins.id

  cidr_ipv4   = each.value
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443

  description = "HTTPS access"
}

############################################################
# Application Ports 3000-9000
############################################################

resource "aws_vpc_security_group_ingress_rule" "application" {
  for_each = toset(var.allowed_web_cidr)

  security_group_id = aws_security_group.jenkins.id

  cidr_ipv4   = each.value
  from_port   = 3000
  ip_protocol = "tcp"
  to_port     = 9000

  description = "Application ports 3000-9000"
}

############################################################
# Egress
############################################################

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.jenkins.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  description = "Allow outbound traffic"
}

############################################################
# EC2 Instance
############################################################

resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true

  user_data = templatefile(
    "${path.module}/templates/jenkins-install.sh",
    {
      ecr_repository = aws_ecr_repository.this.repository_url
    }
  )

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  root_block_device {
    volume_size           = 25
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  monitoring = true

  tags = {
    Name = "${var.project_name}-${var.environment}-jenkins"
  }

  lifecycle {
    create_before_destroy = true
  }
}
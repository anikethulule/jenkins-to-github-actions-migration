aws_region  = "ap-south-1"
project_name = "jenkins-ecr"
environment  = "prod"

instance_type = "t3.medium"

vpc_id    = "vpc-00a08d86afabbf781"
subnet_id = "subnet-0b1317ed4570c1d12"

key_name = "test-migration-key-new"

allowed_ssh_cidr = [
  "0.0.0.0/0"
]

allowed_web_cidr = [
  "0.0.0.0/0"
]

ecr_repository_name = "jenkins-migration-demo"
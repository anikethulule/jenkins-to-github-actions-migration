#!/bin/bash

set -euxo pipefail

exec > >(tee /var/log/jenkins-bootstrap.log | logger -t jenkins-bootstrap -s 2>/dev/console) 2>&1

echo "===== Starting Jenkins EC2 bootstrap ====="

############################################################
# System update
############################################################

export DEBIAN_FRONTEND=noninteractive

apt-get update -y

############################################################
# Base packages
############################################################

apt-get install -y \
  openjdk-21-jdk \
  curl \
  wget \
  git \
  unzip \
  docker.io \
  ca-certificates \
  gnupg

############################################################
# AWS CLI
############################################################

echo "===== Installing AWS CLI ====="

curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
  -o /tmp/awscliv2.zip

rm -rf /tmp/aws
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update
rm -rf /tmp/aws /tmp/awscliv2.zip

############################################################
# Docker
############################################################

echo "===== Configuring Docker ====="

systemctl enable docker
systemctl start docker

usermod -aG docker ubuntu

############################################################
# Jenkins Repository
############################################################

echo "===== Adding Jenkins repository ====="

curl -fsSL \
  https://pkg.origin.jenkins.io/debian-stable/jenkins.io-2026.key \
  -o /usr/share/keyrings/jenkins-keyring.asc

chmod 0644 /usr/share/keyrings/jenkins-keyring.asc

echo \
  "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.origin.jenkins.io/debian-stable/ binary/" \
  > /etc/apt/sources.list.d/jenkins.list

apt-get update -y

############################################################
# Jenkins Installation
############################################################

echo "===== Installing Jenkins ====="

for i in {1..3}; do

  echo "Jenkins installation attempt $i"

  if apt-get install -y jenkins; then
    echo "Jenkins installed successfully"
    break
  fi

  if [ "$i" -lt 3 ]; then
    echo "Installation failed. Retrying in 10 seconds..."
    sleep 10
  else
    echo "ERROR: Jenkins installation failed"
    exit 1
  fi

done

############################################################
# Jenkins + Docker permissions
############################################################

echo "===== Configuring Jenkins Docker access ====="

usermod -aG docker jenkins

############################################################
# Services
############################################################

systemctl enable docker
systemctl restart docker

systemctl enable jenkins
systemctl restart jenkins

############################################################
# Wait for Jenkins
############################################################

echo "===== Waiting for Jenkins ====="

for i in {1..30}; do

  if systemctl is-active --quiet jenkins; then
    echo "Jenkins service is running"
    break
  fi

  echo "Waiting for Jenkins... attempt $i"
  sleep 5

done

############################################################
# Validate installations
############################################################

echo "===== Installation validation ====="

echo "Java:"
java -version

echo "Docker:"
docker --version

echo "AWS CLI:"
aws --version

echo "Jenkins:"
systemctl status jenkins --no-pager || true

echo "Docker:"
systemctl status docker --no-pager || true

############################################################
# ECR information
############################################################

echo "===== ECR Repository ====="
echo "${ecr_repository}"

echo "===== Bootstrap completed ====="
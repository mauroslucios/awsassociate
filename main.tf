terraform {
  backend "local" {

  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "aws" {
  shared_config_files      = ["/home/mauroslucios/.aws/conf"]
  shared_credentials_files = ["/home/mauroslucios/.aws/credentials"]
  profile                  = "default"
  region                   = "us-east-1"
}

resource "aws_instance" "associate" {
  instance_type               = "t2.micro"
  ami                         = "ami-053b0d53c279acc90"
  key_name = var.ami_key_pair_name
  subnet_id                   = var.associate_subnet_public_id
  vpc_security_group_ids      = [aws_security_group.associate_ssh_http.id]
  associate_public_ip_address = true

  tags = {
    Name = "associateaws"
  }
}

resource "aws_security_group" "associate_ssh_http" {
  name        = "permitir_ssh_http"
  description = "permite SSh e HTTP na instancia EC2"
  vpc_id      = var.associate_vpc_id

  ingress {
    description = "HTTP to EC2"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "permitir_ssh_http"
  }
}

resource "aws_key_pair" "associate_key_pair_aws" {
key_name = "associate_key_pair_aws"
public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
algorithm = "RSA"
rsa_bits  = 4096
}
resource "local_file" "associate-key" {
content  = tls_private_key.rsa.private_key_pem
filename = "associate_key_pair_aws"
}
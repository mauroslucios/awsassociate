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
  key_name                    = var.ami_key_pair_name
  subnet_id                   = var.associate_subnet_public_id
  vpc_security_group_ids      = [aws_security_group.associate_ssh_http.id]
  associate_public_ip_address = true

  tags = {
    Name = "associateaws"
  }

  iam_instance_profile = aws_iam_instance_profile.associate_profile.id
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
  key_name   = "associate_key_pair_aws"
  public_key = tls_private_key.rsa.public_key_openssh
}
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "associate_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "associate_key_pair_aws"
}

resource "aws_s3_bucket" "associatebucket" {
  bucket        = "associateawsbucket"
  force_destroy = true
}

resource "aws_s3_object" "folder1" {
    bucket = "${aws_s3_bucket.associatebucket.id}"
    acl    = "private"
    key    = "documents/"
    source = "/dev/null"
  content_type = "application/x-directory"
}
resource "aws_s3_bucket_public_access_block" "associate_block_public_access" {
  bucket = aws_s3_bucket.associatebucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
}

resource "aws_iam_policy" "associate_bucket_policy" {
  name        = "associate_bucket_policy"
  path        = "/"
  description = "Allow"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::*/*",
          "arn:aws:s3:::associateawsbucket"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "associate_some_role" {
  name = "associate_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "associate_bucket_policy" {
  role       = aws_iam_role.associate_some_role.name
  policy_arn = aws_iam_policy.associate_bucket_policy.arn
}

resource "aws_iam_role_policy_attachment" "cloud_watch_policy" {
  role       = aws_iam_role.associate_some_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "associate_profile" {
  name = "associate-some-profile"
  role = aws_iam_role.associate_some_role.name
}
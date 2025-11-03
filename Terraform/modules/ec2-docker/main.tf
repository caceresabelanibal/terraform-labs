data "aws_caller_identity" "me" {}
data "aws_region" "current" {}

# Default VPC y subred
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# SG solo HTTP
resource "aws_security_group" "web" {
  name        = "${var.name}-web-sg"
  description = "Allow HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
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

  tags = { Name = "${var.name}-web" }
}

# IAM Role para Docker+SSM
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "${var.name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Extrae host y tag de image_uri para docker pull
locals {
  image_host = split("/", var.image_uri)[0]
}

# EC2 que ejecuta Docker
resource "aws_instance" "this" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default_subnets.ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.profile.name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail
    exec > >(tee -a /var/log/user-data.log) 2>&1

    dnf update -y
    dnf install -y docker aws-cli amazon-ssm-agent

    systemctl enable --now docker
    systemctl enable --now amazon-ssm-agent

    REGION="${data.aws_region.current.name}"
    IMAGE="${var.image_uri}"
    HOST="${local.image_host}"

    aws ecr get-login-password --region "$REGION" \
      | docker login --username AWS --password-stdin "$HOST"

    docker pull "$IMAGE"
    docker rm -f ${var.name} || true
    docker run -d --restart unless-stopped --name ${var.name} -p 80:80 "$IMAGE"
  EOF

  tags = { Name = var.name }
}

# AMI Amazon Linux 2023
data "aws_ami" "al2023" {
  owners      = ["137112412989"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

output "public_ip" { value = aws_instance.this.public_ip }
output "public_dns" { value = aws_instance.this.public_dns }
output "app_url" {
  value = "http://${aws_instance.this.public_dns}"
}


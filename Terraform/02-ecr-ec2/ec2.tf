data "aws_caller_identity" "me" {}
data "aws_region" "current" {}

# Default VPC + first subnet
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# SG solo HTTP (80)
resource "aws_security_group" "vt_web" {
  name        = "vt_web_sg"
  description = "Allow HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# AMI Amazon Linux 2023
data "aws_ami" "al2023" {
  owners      = ["137112412989"] # Amazon
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# EC2 que hace pull y run del contenedor
# EC2 que hace pull y run del contenedor
resource "aws_instance" "vt_ec2" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default_subnets.ids[0]
  vpc_security_group_ids = [aws_security_group.vt_web.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  root_block_device {
    volume_size = 20 # GB
    volume_type = "gp3"
  }


  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail
    exec > >(tee -a /var/log/user-data.log) 2>&1

    # Paquetes para Amazon Linux 2023
    dnf update -y
    dnf install -y docker aws-cli amazon-ssm-agent

    systemctl enable --now docker
    systemctl enable --now amazon-ssm-agent

    REGION="${var.region}"
    REPO_URL="${var.repo_url}"
    TAG="${var.image_tag}"
    HOST="$(echo "$REPO_URL" | awk -F/ '{print $1}')"

    # Login ECR
    aws ecr get-login-password --region "$REGION" \
      | docker login --username AWS --password-stdin "$HOST"


    docker pull "$${REPO_URL}:$${TAG}"
    docker rm -f vulneratrack || true
    docker run -d --restart unless-stopped --name vulneratrack -p 80:80 "$${REPO_URL}:$${TAG}"
  EOF

  tags = { Name = "vt-ec2" }
}

output "ec2_public_ip" { value = aws_instance.vt_ec2.public_ip }
output "ec2_public_dns" { value = aws_instance.vt_ec2.public_dns }
output "app_url" { value = "http://${aws_instance.vt_ec2.public_dns}" }


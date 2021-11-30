# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}

data "aws_ami" "ubuntu_master" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20211115-aced0818-eef1-427a-9e04-8ba38bada306"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

}

# Put your IP here to whitelist it for ssh

variable "home_net" {
    type    = string
    default = "104.51.210.204/32"

}

resource "aws_security_group" "phishing_group" {
  name        = "phishing_group"
  description = "Allow Ports for Management and Phishing Services"

  # Open common web ports for C2
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # GoPhish Portal 
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.home_net]
  }

  # ssh for remote access, might want to lock down to your IP prior to rolling out
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.home_net]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "Primary_Phish" {
  ami             = data.aws_ami.ubuntu_master.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.phishing_group.name]
  key_name        = "aalmaguer-01"

  tags = {
    Name = "Primary_Phish"
  }
}

output "IP" {
  value = aws_instance.Primary_Phish.public_ip
}

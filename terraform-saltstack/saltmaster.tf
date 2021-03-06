# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}

data "aws_ami" "ubuntu_master" {
  most_recent = "true"
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-20210928-3b73ef49-208f-47e1-8a6e-4ae768d8a333"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# Put your IP here to whitelist it for ssh

variable "access_addr" {
    type    = string
    default = "0.0.0.0/0"

}

resource "aws_security_group" "salt_group" {
  name        = "salt_group"
  description = "Allow Ports for salt master and ssh access"

  # Open the default Opensalt Port. It's recommdended you scope this to internal IP space but that all depends on the scope of your configuration
  ingress {
    from_port   = 4505
    to_port     = 4506
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ssh for remote access, might want to lock down to your IP prior to rolling out
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.access_addr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "primary_salt" {

  ami             = data.aws_ami.ubuntu_master.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.salt_group.name]
  key_name        = "aalmaguer-rsa"


  tags = {
    Name = "Primary salt"
  }
}


output "Salt_Master" {
  value = aws_instance.primary_salt.public_ip
}

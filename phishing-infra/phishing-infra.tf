# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
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
  key_name        = "almaguer-01"

  provisioner "remote-exec" {
    script        = "install_gophish.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/almaguer-01.pem")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "config.json"
    destination = "/home/ubuntu/go/src/github.com/gophish/gophish/config.json"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/almaguer-01.pem")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "run_gophish.sh"
    destination = "/home/ubuntu/run_gophish.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/almaguer-01.pem")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = ["chmod +x /home/ubuntu/run_gophish.sh"]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/almaguer-01.pem")
      host        = self.public_ip
    }
  }

  provisioner "file" {
    source      = "gophish.service"
    destination = "/home/ubuntu/gophish.service"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/almaguer-01.pem")
      host        = self.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /home/ubuntu/gophish.service /etc/systemd/system/gophish.service",
      "sudo ls -la /etc/systemd/system/gophish.service",
      "sudo systemctl start gophish",
      "sleep 3",
      "cat /var/log/gophish.err | grep -Eo \"password \\w+\""
      ]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/almaguer-01.pem")
      host        = self.public_ip
    }
  }

  tags = {
    Name = "Primary_Phish"
  }
}

output "IP" {
  value = aws_instance.Primary_Phish.public_ip
}

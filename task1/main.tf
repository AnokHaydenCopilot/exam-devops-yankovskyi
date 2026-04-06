terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "yankovskyi-terraform-state-exam"
    key    = "state/terraform.tfstate"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "yankovskyi_vpc" {
  cidr_block = "10.10.10.0/24"
  tags = {
    Name = "yankovskyi-vpc"
  }
}

resource "aws_subnet" "yankovskyi_subnet" {
  vpc_id                  = aws_vpc.yankovskyi_vpc.id
  cidr_block              = "10.10.10.0/25"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "yankovskyi_igw" {
  vpc_id = aws_vpc.yankovskyi_vpc.id
}

resource "aws_route_table" "yankovskyi_rt" {
  vpc_id = aws_vpc.yankovskyi_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.yankovskyi_igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.yankovskyi_subnet.id
  route_table_id = aws_route_table.yankovskyi_rt.id
}

resource "aws_security_group" "yankovskyi_firewall" {
  name        = "yankovskyi-firewall"
  description = "Security rules for Exam"
  vpc_id      = aws_vpc.yankovskyi_vpc.id

  dynamic "ingress" {
    for_each = [22, 80, 443, 8000, 8001, 8002, 8003]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 1
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

resource "aws_key_pair" "yankovskyi_keypair" {
  key_name   = "yankovskyi-aws-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDWvzJuCEnoB9at5o7l/v5bMh4PVt9Okk6YsBB8qYHiu28ZslWsiPffsYaqE8+bYzA0r4kMQ608DN4S6i2/2irCMRO03zQH4zBPlw5IoH/VaSMaqf5UB0aviK+Wm5r5xHPFCqNxAqmGMCdq2hIE8ugCTJUpKKXiDtMwQerM9P4L55imU0ZJfNwPNEc5cUyJ9HHotZOOVru2RBDBFygLR3IbimrF5aU8Bjc0zQDauzDbqVjK4IjTyU8/t/quzTP8bXThljk0B/+OrCFdNMqiLgxV3haQwV8dGrkLTW7wIkDJusn6imOPFs99LT0Tt4Jp1bMkJ65P6lALmeWV/1dNtc3vH7FHQpXvAYcf5K0WUE0+078u4eAei0uC/8D2WdIGkq9b5tW7OSNqJuHMymz4VZasLWils0m83I/Mopb4UR0tLwKZzBlPP/2NTKVTD9LQeb2QNiMB5fST51vFjjW87BIm+Ts+pyplzEZiaI1WbUSFK8241NruNbN6JQ2d8JyWB2AW6KJkmBJuH/4r0qLH50ZcwvIhd3A0eymH6P0evKy3kxVnCChDTiXoRnVN07dbg5v4vf1XEAZkrmn+gMKk9W73pRCrzPrg08Bb2nGOl/a8Jf22W+VNrRQLohEmUKRihOHqCZ9Sf1vbsU0RZ1XBgAl4F0xWVGTrRb2jSDn0PV3gxw== moder@MSI"
}

resource "aws_instance" "yankovskyi_node" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "m7i-flex.large"
  subnet_id     = aws_subnet.yankovskyi_subnet.id
  vpc_security_group_ids = [aws_security_group.yankovskyi_firewall.id]
  key_name      = aws_key_pair.yankovskyi_keypair.key_name

  tags = {
    Name = "yankovskyi-node"
  }
}

resource "random_pet" "bucket_suffix" {}

resource "aws_s3_bucket" "yankovskyi_bucket" {
  bucket = "yankovskyi-bucket-${random_pet.bucket_suffix.id}"
}

output "instance_public_ip" {
  value = aws_instance.yankovskyi_node.public_ip
}

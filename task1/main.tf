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

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "ssh_key_name" {
  type    = string
  default = "yankovskyi-ci-key"
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "bucket_name" {
  type    = string
  default = "yankovskyi-bucket"
}

# m7i-flex.large: 2 vCPU, 8 GiB RAM — meets Minikube/K8s system requirements
variable "instance_type" {
  type    = string
  default = "m7i-flex.large"
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.10.0/24"
}

variable "subnet_cidr" {
  type    = string
  default = "10.10.10.0/25"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "yankovskyi_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "yankovskyi-vpc"
  }
}

resource "aws_subnet" "yankovskyi_subnet" {
  vpc_id                  = aws_vpc.yankovskyi_vpc.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "yankovskyi-subnet"
  }
}

resource "aws_internet_gateway" "yankovskyi_igw" {
  vpc_id = aws_vpc.yankovskyi_vpc.id

  tags = {
    Name = "yankovskyi-igw"
  }
}

resource "aws_route_table" "yankovskyi_rt" {
  vpc_id = aws_vpc.yankovskyi_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.yankovskyi_igw.id
  }
  tags = {
    Name = "yankovskyi-rt"
  }
}

resource "aws_route_table_association" "yankovskyi_rta" {
  subnet_id      = aws_subnet.yankovskyi_subnet.id
  route_table_id = aws_route_table.yankovskyi_rt.id
}

resource "aws_security_group" "yankovskyi_firewall" {
  name        = "yankovskyi-firewall"
  description = "Firewall rules for Yankovskyi exam"
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

  # Allow all outbound traffic (ports 1-65535 TCP + UDP + ICMP)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "yankovskyi-firewall"
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
  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "yankovskyi_keypair" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key
}

resource "aws_instance" "yankovskyi_node" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.yankovskyi_subnet.id
  vpc_security_group_ids      = [aws_security_group.yankovskyi_firewall.id]
  key_name                    = aws_key_pair.yankovskyi_keypair.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }

  tags = {
    Name = "yankovskyi-node"
  }
}

# Store instance IP in SSM so other workflows can retrieve it without manual input
resource "aws_ssm_parameter" "instance_ip" {
  name  = "/yankovskyi/ec2/instance_ip"
  type  = "String"
  value = aws_instance.yankovskyi_node.public_ip

  tags = {
    Name = "yankovskyi-instance-ip"
  }
}

resource "aws_s3_bucket" "yankovskyi_bucket" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name = "yankovskyi-bucket"
  }
}

resource "aws_s3_bucket_versioning" "yankovskyi_bucket_versioning" {
  bucket = aws_s3_bucket.yankovskyi_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "yankovskyi_bucket_block" {
  bucket                  = aws_s3_bucket.yankovskyi_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

output "instance_public_ip" {
  value       = aws_instance.yankovskyi_node.public_ip
  description = "Public IP of the EC2 node"
}

output "bucket_name" {
  value       = aws_s3_bucket.yankovskyi_bucket.bucket
  description = "Name of the S3 bucket"
}

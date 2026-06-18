locals {
  common_tags = merge(
    {
      Project = var.name_prefix
    },
    var.tags
  )

  selected_vpc_id    = var.create_vpc ? aws_vpc.this[0].id : var.vpc_id
  selected_subnet_id = var.create_vpc ? aws_subnet.public[0].id : var.subnet_id
}

resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  count = var.create_vpc ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  count = var.create_vpc ? 1 : 0

  vpc_id                  = aws_vpc.this[0].id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone != "" ? var.availability_zone : null
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-public"
  })
}

resource "aws_route_table" "public" {
  count = var.create_vpc ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-public"
  })
}

resource "aws_route_table_association" "public" {
  count = var.create_vpc ? 1 : 0

  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public[0].id
}

data "aws_vpc" "existing" {
  count = var.create_vpc ? 0 : 1

  id = var.vpc_id
}

data "aws_subnet" "existing" {
  count = var.create_vpc ? 0 : 1

  id = var.subnet_id
}

resource "aws_security_group" "proxy" {
  name        = "${var.name_prefix}-sg"
  description = "Allow public HTTP/HTTPS and restricted SSH to the NGINX proxy"
  vpc_id      = local.selected_vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.http_cidrs
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.https_cidrs
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-sg"
  })
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "proxy" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = local.selected_subnet_id
  vpc_security_group_ids      = [aws_security_group.proxy.id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  user_data_replace_on_change = true

  user_data = templatefile("${path.module}/user-data.sh.tpl", {
    tls_mode               = var.tls_mode
    domain_name            = var.domain_name
    letsencrypt_email      = var.letsencrypt_email
    letsencrypt_staging    = var.letsencrypt_staging
    letsencrypt_auto_issue = var.letsencrypt_auto_issue
  })

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }

  tags = merge(local.common_tags, {
    Name = var.name_prefix
  })
}

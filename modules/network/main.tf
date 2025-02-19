# modules/network/main.tf
variable "aws_region" {}
variable "vpc_cidr_block" {}
variable "studio_name" {}
variable "broker_hostname" {}
variable "broker_private_ip" {}
variable "internal_domain_name" {}

resource "aws_vpc" "leostream_vpc" {
  cidr_block           = var.vpc_cidr_block 
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name   = "Leostream-VPC"
    Project = "leostream-test"
    Owner   = "test user"
  }
}

resource "aws_internet_gateway" "leostream_igw" {
  vpc_id = aws_vpc.leostream_vpc.id
  tags = {
    Name = "Leostream-IGW"
    Project = "leostream-test"
    Owner = "test user"
  }
}

resource "aws_subnet" "leostream_public_subnet" {
  vpc_id                  = aws_vpc.leostream_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 10, 0)
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Leostream-Public-Subnet"
    Project = "leostream-test"
    Owner = "test user"
  }
}

resource "aws_subnet" "ad_private_subnet_1" {
  vpc_id                  = aws_vpc.leostream_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 10, 1)
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Leostream-Private-Subnet-1"
    Project = "leostream-test"
    Owner = "test user"
  }
}

resource "aws_subnet" "ad_private_subnet_2" {
  vpc_id                  = aws_vpc.leostream_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 10, 2)
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false

  tags = {
    Name = "Leostream-Private-Subnet-2"
    Project = "leostream-test"
    Owner = "test user"
  }
}

resource "aws_subnet" "workstation_private_subnet" {
  vpc_id                  = aws_vpc.leostream_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 10, 3)
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name    = "Leostream-Workstation-Private-Subnet"
    Project = "leostream-test"
    Owner   = "test user"
  }
}

# SSM Endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.leostream_vpc.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.workstation_private_subnet.id]  
  security_group_ids  = [aws_security_group.ssm_endpoint.id] 

  tags = {
    Name = "SSM-VPC-Endpoint"
    Project = "leostream-test"
    Owner   = "test user"
  }
}

# Security Group for SSM Endpoint
resource "aws_security_group" "ssm_endpoint" {
  name        = "SSM-Endpoint-SG"
  description = "Allow inbound traffic for SSM endpoint"
  vpc_id      = aws_vpc.leostream_vpc.id

  ingress {
    description = "Allow SSM traffic from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SSM-Endpoint-SG"
    Project = "leostream-test"
    Owner   = "test user"
  }
}

resource "aws_route_table" "leostream_public" {
  vpc_id = aws_vpc.leostream_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.leostream_igw.id
  }

  tags = {
    Name = "Leostream-Public-RT"
    Project = "leostream-test"
    Owner = "test user"
  }
}

resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.leostream_public_subnet.id
  route_table_id = aws_route_table.leostream_public.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.leostream_vpc.id

  route {
    cidr_block = var.vpc_cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "Leostream-Private-RT"
    Project = "leostream-test"
    Owner = "test user"
  }
}

resource "aws_route_table_association" "private_rta_1" {
  subnet_id      = aws_subnet.ad_private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rta_2" {
  subnet_id      = aws_subnet.ad_private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "leostream_nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.leostream_public_subnet.id

  tags = {
    Name    = "Leostream-NAT-Gateway"
    Project = "leostream-test"
    Owner   = "test user"
  }
}

resource "aws_route_table" "workstation_private_rt" {
  vpc_id = aws_vpc.leostream_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.leostream_nat_gateway.id
  }

  tags = {
    Name    = "Leostream-Workstation-Private-RT"
    Project = "leostream-test"
    Owner   = "test user"
  }
}

resource "aws_route_table_association" "workstation_private_rta" {
  subnet_id      = aws_subnet.workstation_private_subnet.id
  route_table_id = aws_route_table.workstation_private_rt.id
}


resource "aws_route53_zone" "leostream_internal_zone" {
  name = var.internal_domain_name
  vpc {
    vpc_id = aws_vpc.leostream_vpc.id
  }
}

# SRV Record for Leostream Connection Broker
resource "aws_route53_record" "leostream_connection_broker_srv" {
  zone_id = aws_route53_zone.leostream_internal_zone.zone_id
  name    = "_connection_broker._tcp"
  type    = "SRV"
  ttl     = "300"

  records = [
    "0 100 443 ${var.broker_hostname}.${var.internal_domain_name}."
  ]
}

# A Record for Leostream Broker
resource "aws_route53_record" "leostream_broker_dns" {
  zone_id = aws_route53_zone.leostream_internal_zone.zone_id
  name    = var.broker_hostname
  type    = "A"
  ttl     = "300"
  records = [var.broker_private_ip]
}

output "vpc_id" {
  value = aws_vpc.leostream_vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.leostream_public_subnet.id
}

output "workstation_private_subnet_id" {
  value = aws_subnet.workstation_private_subnet.id
}

output "ad_private_subnet_ids" {
  value = [aws_subnet.ad_private_subnet_1.id, aws_subnet.ad_private_subnet_2.id]
}

output "vpc_cidr_block" {
  value = var.vpc_cidr_block
}
# modules/active_directory/main.tf
variable "vpc_id" {}
variable "ad_private_subnet_ids" {}
variable "aws_region" {}
variable "studio_name" {}
variable "vpc_cidr_block" {}
variable "ad_admin_password" {}

resource "aws_directory_service_directory" "leostream_ad" {
  type       = "MicrosoftAD"
  edition    = "Enterprise"
  short_name = "ad"
  name       = "ad.${replace(var.studio_name, "_", "-")}.leostream-studio.${var.aws_region}.aws"
  password   = var.ad_admin_password
  size       = "Large"

  vpc_settings {
    vpc_id     = var.vpc_id
    subnet_ids = var.ad_private_subnet_ids
  }

  tags = {
    Name   = "AWS-Managed-AD"
    Project = "leostream-test"
    Owner   = "test user"
  }
}

resource "aws_vpc_dhcp_options" "leostream_dhcp_options" {
  domain_name = "ad.${replace(var.studio_name, "_", "-")}.leostream-studio.${var.aws_region}.aws"
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "leostream_dhcp_assoc" {
  vpc_id          = var.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.leostream_dhcp_options.id
}


resource "aws_security_group" "outbound_dns" {
  name        = "OutboundDNS-SG"
  description = "Security group for outbound DNS queries"
  vpc_id      = var.vpc_id

  egress {
    from_port = 53
    protocol  = "tcp"
    to_port   = 53
    cidr_blocks = [var.vpc_cidr_block] # Assuming your VPC CIDR, adjust if different
    description = "Allow outbound DNS queries to AD"
  }

  egress {
    from_port = 53
    protocol  = "udp"
    to_port   = 53
    cidr_blocks = [var.vpc_cidr_block] # Assuming your VPC CIDR, adjust if different
    description = "Allow outbound DNS queries to AD"
  }

  tags = {
    Name   = "OutboundDNS-SG"
    Project = "leostream-test"
    Owner   = "test user"
  }
}

resource "aws_route53_resolver_endpoint" "outbound_resolver" {
  name               = "Leostream-Outbound-Resolver"
  direction          = "OUTBOUND"
  security_group_ids = [aws_security_group.outbound_dns.id]

  dynamic "ip_address" {
    for_each = var.ad_private_subnet_ids
    content {
      subnet_id = ip_address.value
    }
  }
}

resource "aws_route53_resolver_rule" "ad_dns_rule" {
  domain_name = aws_directory_service_directory.leostream_ad.name
  rule_type   = "FORWARD"
  name        = "Leostream-AD-DNS-Forwarder"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound_resolver.id

  dynamic "target_ip" {
    for_each = aws_directory_service_directory.leostream_ad.dns_ip_addresses
    content {
      ip = target_ip.value
    }
  }
}

resource "aws_route53_resolver_rule_association" "ad_dns_rule_assoc" {
  resolver_rule_id = aws_route53_resolver_rule.ad_dns_rule.id
  vpc_id           = var.vpc_id
}


output "ad_dns_ip_addresses" {
  value = aws_directory_service_directory.leostream_ad.dns_ip_addresses
}

output "ad_name" {
  value = aws_directory_service_directory.leostream_ad.name
}


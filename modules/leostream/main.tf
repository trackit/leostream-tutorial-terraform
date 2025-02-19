# modules/leostream/main.tf

variable "vpc_id" {}
variable "public_subnet_id" {}
variable "broker_ami_id" {}
variable "gateway_ami_id" {}
variable "personal_ip" {}
variable "vpc_cidr_block" {}

resource "aws_security_group" "leostream_sg" {
  name        = "Leostream-SG"
  description = "Security group for Leostream services"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.personal_ip]
  }

  ingress {
    description = "Allow RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.personal_ip]
  }

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.personal_ip]
  }

  ingress {
    description = "Allow HTTPS to communicate with gateway"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.personal_ip]
  }

  ingress {
    description = "Allow Leostream Agent Communication"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block] 
  }

  ingress {
    description = "Allow DCV Web UI"
    from_port   = 8843
    to_port     = 8843
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block] 
  }

  ingress {
    description = "Allow Nice DCV from Personal IP"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [var.personal_ip]
  }

  ingress {
    description = "Allow LDAP from Leostream Broker"
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block] 
  }

  ingress {
    description = "Allow LDAPS from Leostream Broker"
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block] 
  }

  ingress {
    description = "Allow Kerberos from Leostream Broker"
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block] 
  }

  ingress {
    description = "Allow DNS from Leostream Broker"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = "Leostream-SG"
    Project = "leostream-test"
    Owner   = "test user"
  }
}

resource "aws_security_group" "leostream_gateway_sg" {
  name        = "Leostream-Gateway-SG"
  description = "Security group for Leostream Gateway"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow DCV from Internet"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [var.personal_ip]
  }

  ingress {
    description = "Allow DCV dynamic ports from Internet"
    from_port   = 20001
    to_port     = 23000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow DCV dynamic ports from Internet"
    from_port   = 20001
    to_port     = 23000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from external client"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.personal_ip]
  }

    ingress {
    description = "Allow HTTPS from broker"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.personal_ip]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.personal_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name   = "Leostream-Gateway-SG"
    Project = "leostream-test"
    Owner   = "test user"
  }
}

resource "aws_iam_role" "leostream_role" {
  name = "leostream-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "leostream_role_ec2_full_access" {
  role       = aws_iam_role.leostream_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_instance_profile" "leostream_instance_profile" {
  name = "leostream-profile"
  role = aws_iam_role.leostream_role.name
}

resource "tls_private_key" "leostream_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_secretsmanager_secret" "leostream_ssh_secret" {
  name        = "leostream-ssh-private-key"
  description = "Private key for accessing the Leostream instance"
}

resource "aws_secretsmanager_secret_version" "leostream_ssh_secret_version" {
  secret_id     = aws_secretsmanager_secret.leostream_ssh_secret.id
  secret_string = tls_private_key.leostream_key.private_key_pem
}

resource "aws_key_pair" "leostream_key_pair" {
  key_name   = "leostream-key"
  public_key = tls_private_key.leostream_key.public_key_openssh
}

resource "aws_instance" "leostream_broker_instance" {
  ami           = var.broker_ami_id
  instance_type = "t3.large"
  subnet_id     = var.public_subnet_id
  vpc_security_group_ids = [
    aws_security_group.leostream_sg.id
  ]
  iam_instance_profile = aws_iam_instance_profile.leostream_instance_profile.name
  key_name             = aws_key_pair.leostream_key_pair.key_name
  private_dns_name_options {
    enable_resource_name_dns_a_record = true
    hostname_type                     = "resource-name"
  }

  tags = {
    Name = "leostream-broker"
    Project = "leostream-test"
    Owner   = "test user"
  }
}

# Leostream gateway resources

resource "aws_eip" "leostream_gateway_eip" {
  domain = "vpc"
}

resource "aws_instance" "leostream_gateway_instance" {
  ami           = var.gateway_ami_id
  instance_type = "t3.large"
  associate_public_ip_address = true
  subnet_id     = var.public_subnet_id
  vpc_security_group_ids = [
    aws_security_group.leostream_gateway_sg.id
  ]
  iam_instance_profile = aws_iam_instance_profile.leostream_instance_profile.name
  key_name             = aws_key_pair.leostream_key_pair.key_name

  user_data = <<-EOF
              #!/bin/bash
              sudo leostream-gateway --broker ${aws_instance.leostream_broker_instance.private_ip}
              EOF

  tags = {
    Name   = "Leostream-Gateway"
    Project = "leostream-test"
    Owner   = "test user"
  }

  depends_on = [aws_instance.leostream_broker_instance,aws_eip.leostream_gateway_eip]
}

# Associate the EIP with the instance
resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.leostream_gateway_instance.id
  allocation_id = aws_eip.leostream_gateway_eip.id
}

### Activate the following for ALB + subdomain Route53 DNS A record
/* # Define the ALB
resource "aws_lb" "leostream_alb" {
  name               = "leostream-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.leostream_sg.id]
  subnets            = [var.public_subnet_id]

  enable_deletion_protection = false

  tags = {
    Name   = "Leostream-ALB"
    Project = "leostream-test"
    Owner   = "test user"
  }
}

# Define the Target Group
resource "aws_lb_target_group" "leostream_tg" {
  name     = "leostream-tg"
  port     = 8443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name   = "Leostream-TG"
    Project = "leostream-test"
    Owner   = "test user"
  }
}

# Define the Listener
resource "aws_lb_listener" "leostream_listener" {
  load_balancer_arn = aws_lb.leostream_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn  # You need to provide a valid ACM certificate ARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.leostream_tg.arn
  }
}

# Register the Gateway Instances with the Target Group
resource "aws_lb_target_group_attachment" "leostream_tg_attachment" {
  count            = length(aws_instance.leostream_gateway_instance)
  target_group_arn = aws_lb_target_group.leostream_tg.arn
  target_id        = aws_instance.leostream_gateway_instance[count.index].id
  port             = 8443
}

# Create a Route 53 Record for the Subdomain
resource "aws_route53_record" "leostream_subdomain" {
  zone_id = var.route53_zone_id  # You need to provide a valid Route 53 hosted zone ID
  name    = "leostream.yourdomain.com"  # Replace with your desired subdomain
  type    = "A"

  alias {
    name                   = aws_lb.leostream_alb.dns_name
    zone_id                = aws_lb.leostream_alb.zone_id
    evaluate_target_health = true
  }
}

# Add the following variables to your variables.tf file
variable "certificate_arn" {
  description = "The ARN of the ACM certificate for the load balancer"
}

variable "route53_zone_id" {
  description = "The Route 53 hosted zone ID for the subdomain"
} */



output "broker_private_ip" {
  value = aws_instance.leostream_broker_instance.private_ip
}

output "leostream_broker_sg_id" {
  value = aws_security_group.leostream_sg.id
}

output "leostream_gateway_sg_id" {
  value = aws_security_group.leostream_gateway_sg.id
}

output "broker_hostname" {
  value = aws_instance.leostream_broker_instance.tags.Name
}
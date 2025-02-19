# modules/workstation/main.tf

variable "vpc_id" {}
variable "aws_region" {}
variable "workstation_private_subnet_id" {}
variable "workstation_ami_id" {}
variable "leostream_broker_sg_id" {}
variable "leostream_gateway_sg_id" {}
variable "vpc_cidr_block" {}
variable "personal_ip" {}

# IAM Role for Workstation Instances
resource "aws_iam_role" "workstation_role" {
  name = "leostream-workstation-role"
  
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

# Inline Policy for DCV licensing S3 Access
resource "aws_iam_role_policy" "workstation_s3_policy" {
  name = "workstation-dcv-licensing-s3-policy"
  role = aws_iam_role.workstation_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::dcv-license.${var.aws_region}/*"
      }
    ]
  })
}

# Enable SSM on workstations
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.workstation_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "workstation_instance_profile" {
  name = "leostream-workstation-profile"
  role = aws_iam_role.workstation_role.name
}

# EC2 Launch Template Workstation
resource "aws_launch_template" "leostream_template" {
  name          = "leostream-launch-template-workstation"
  image_id      = var.workstation_ami_id
  iam_instance_profile {
    name = aws_iam_instance_profile.workstation_instance_profile.name
  }
  network_interfaces {
    subnet_id       = var.workstation_private_subnet_id
    security_groups = [aws_security_group.workstation_leostream_sg.id] 
  }
  user_data = base64encode(<<-EOF
    <powershell>
    # Get the current DNS suffix search list
    $currentSuffixes = (Get-DnsClientGlobalSetting).SuffixSearchList

    # Add leostream.internal to the list if it's not already there
    if ($currentSuffixes -notcontains "leostream.internal") {
      $newSuffixes = $currentSuffixes + "leostream.internal"
      Set-DnsClientGlobalSetting -SuffixSearchList $newSuffixes
    }
    </powershell>
    EOF
  )
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name   = "Leostream-Instance"
      Project = "leostream-test"
      Owner   = "test user"
    }
  }
}

resource "aws_security_group" "workstation_leostream_sg" {
  name        = "Leostream-Workstation-SG"
  description = "Security group for Leostream workstations"
  vpc_id      = var.vpc_id

  # Rules for Leostream Gateway

  ingress {
    description = "Allow DCV from Leostream Gateway"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    security_groups = [var.leostream_gateway_sg_id]
  }

  ingress {
    description = "Allow Communication from Leostream broker"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    description = "Allow Communication from Leostream broker"
    from_port   = 8080
    to_port     = 8080
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr_block]
  }


  # Rules for AD integration
  ingress {
    description = "Allow DNS from AD"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr_block] 
  }

  ingress {
    description = "Allow DNS from AD (TCP)"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]  
  }

  ingress {
    description = "Allow Kerberos from AD"
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block] 
  }

  ingress {
    description = "Allow LDAP from AD"
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block] 
  }

  ingress {
    description = "Allow LDAPS from AD"
    from_port   = 636
    to_port     = 636
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
    Name   = "Leostream-Workstation-SG"
    Project = "leostream-test"
    Owner   = "test user"
  }
}

resource "aws_security_group" "ami_builder_leostream_sg" {
  name        = "Leostream-AMI-Builder-SG"
  description = "Security group for Leostream workstations AMI builder"
  vpc_id      = var.vpc_id

  # RDP from Admin ip

  ingress {
    description = "Allow RDP to admin IP"
    from_port   = 3389
    to_port     = 3389
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
    Name   = "Leostream-Workstation-AMI-Builder-SG"
    Project = "leostream-test"
    Owner   = "test user"
  }
}
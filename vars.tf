// --== GENERAL SECTION ==--
variable "aws_region" {
  type        = string
  description = "The AWS region to use for all deployment, ex: us-west-2"
}

variable "studio_name" {
  type = string
  description = "The friendly name for your studio"
}

variable "vpc_cidr_block" {
  type = string
  description = "Enter the studio IP range (must be a /16 range, use 10.0.0.0/16 if you don't know what to use)"
}

variable "ad_admin_password" {
  description = "The password for the Active Directory admin account."
  type        = string
  sensitive   = true
}

variable "leostream_broker_ami_id" {
  description = "The AMI id of Leostream broker, look on the market place for latest ami, current early 2025 ami-07489906c18907ec4"
  type        = string
}

variable "leostream_gateway_ami_id" {
  description = "The AMI id of Leostream gateway, look on the market place for latest ami, current early 2025 ami-09b0d468d5c9f9936"
  type        = string
}

variable "launch_template_workstation_ami_id" {
  description = "The AMI id for workstation"
  type        = string
}

variable "personal_ip" {
  description = "Personal public ip for testing/troubleshooting, include the /32 range"
  type        = string
}

variable "internal_domain_name" {
  type        = string
  description = "The internal domain name for the private DNS zone, default is leostream.internal"
  default     = "leostream.internal"
}
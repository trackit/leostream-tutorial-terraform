module "network" {
  source = "./modules/network"
  aws_region = var.aws_region
  vpc_cidr_block = var.vpc_cidr_block
  studio_name = var.studio_name
  internal_domain_name = var.internal_domain_name
  broker_hostname = module.leostream.broker_hostname
  broker_private_ip = module.leostream.broker_private_ip
}

module "active_directory" {
  source = "./modules/active_directory"
  vpc_id = module.network.vpc_id
  ad_private_subnet_ids = module.network.ad_private_subnet_ids
  aws_region = var.aws_region
  studio_name = var.studio_name
  ad_admin_password = var.ad_admin_password
  vpc_cidr_block = module.network.vpc_cidr_block
}

module "leostream" {
  source = "./modules/leostream"
  vpc_id = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_id
  broker_ami_id = var.leostream_broker_ami_id
  gateway_ami_id = var.leostream_gateway_ami_id
  personal_ip = var.personal_ip
  vpc_cidr_block = module.network.vpc_cidr_block
}

module "workstation" {
  source = "./modules/workstation"
  vpc_id = module.network.vpc_id
  workstation_private_subnet_id = module.network.workstation_private_subnet_id
  workstation_ami_id = var.launch_template_workstation_ami_id
  leostream_broker_sg_id = module.leostream.leostream_broker_sg_id
  leostream_gateway_sg_id = module.leostream.leostream_gateway_sg_id
  vpc_cidr_block = module.network.vpc_cidr_block
  aws_region = var.aws_region
  personal_ip = var.personal_ip
}
output "broker_private_ip" {
  value = module.leostream.broker_private_ip
}
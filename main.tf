#
# Define a VPC with a private subnet, VPC Endpoints & security groups
# Create a t2.micro EC2 instance with an instance role
#
locals {
  friendly_name   = "SSH no SSH"
  cost_allocation = "work"
}

#
# Create a new VPC to isolate resources from the evil Internets...
#
module "vpc" {
  source = "./modules/VPC"

  tag_Name            = local.friendly_name
  tag_cost_allocation = local.cost_allocation
}

#
# Create an EC2 instance for this demo
#
module "ec2" {
  source = "./modules/EC2"

  subnet_id = module.vpc.private_subnet_id

  security_group_id = [module.vpc.ec2_security_group_id]

  tag_Name            = local.friendly_name
  tag_cost_allocation = local.cost_allocation

  #
  # Force the creation of the EC2 to wait until the VPC is all there
  # because the EC2 user data is dependent on the access to the S3
  # VPC Endpoint
  #
  depends_on = [ module.vpc ]
}
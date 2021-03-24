#
# Define a VPC with a private subnet and an empty (no ingress or egress rules) security group.
# Create a t2.micro EC2 instance with an instance role
#
locals {
  friendly_name   = "SSH no port 22"
  cost_allocation = "work"
}

#
# 
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

  security_group_id = [module.vpc.security_group_id]

  tag_Name            = local.friendly_name
  tag_cost_allocation = local.cost_allocation
}
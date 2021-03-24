#
# https://www.terraform.io/docs/language/values/outputs.html
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc#attributes-reference
#

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID of the newly minted VPC"
}

output "private_subnet_id" {
  value       = module.vpc.private_subnet_id
  description = "ID of the private subnet"
}

output "ami_id" {
  value       = module.ec2.ami_id
  description = "ID of the AMI used"
}
#
# The VPC will have a single private subnet, no Internet gateway, VPC Endpoints to the
# required services (EC2, EC2 Messages, SSM, SSM Messages, Logs & S3) and two security
# groups, one for isolating the EC2 instance, the other for the VPC Endpoints (although
# I'm quite sure, for this demo, just one would do)... The VPC Endpoints don't have
# policies
#

#
# Add to the list as required if required...
#
locals {
  vpc_endpoints = {
    ssm = "SSM"
    ssmmessages = "SSM Messages"
    ec2 = "EC2"
    ec2messages = "EC2 Messages"
    logs = "CloudWatch Logs"
###    kms = "KMS"
  }
}

resource "aws_vpc" "ssh" {
  cidr_block = var.cidr_block

  enable_dns_hostnames = true

  tags = {
    Name              = var.tag_Name
    "cost:allocation" = var.tag_cost_allocation
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.ssh.id
  cidr_block = var.private_subnet_cidr_block
  tags = {
    Name              = "Private"
    "cost:allocation" = var.tag_cost_allocation
  }
}

#
# VPC Endpoints
#
resource "aws_vpc_endpoint" "ssh_interfaces" {
  vpc_id     = aws_vpc.ssh.id
  subnet_ids = [ aws_subnet.private.id ]

  for_each = local.vpc_endpoints
  service_name = "com.amazonaws.${data.aws_region.current.name}.${each.key}"

  vpc_endpoint_type   = "Interface"
  security_group_ids  = [ aws_security_group.vpce.id ]
  private_dns_enabled = true

  tags = {
    Name               = each.value
    "cost:allocation"  = var.tag_cost_allocation
    "resource:context" = var.tag_resource_context
  }
}

#
# The S3 access is needed because at the time of writing, the SSM Agent in the
# Amazon Linux 2 instance doesn't have the version that supports streaming
# commands... shame, but the version needs to be 3.0.356.0 or above:
# https://github.com/aws/amazon-ssm-agent/blob/mainline/RELEASENOTES.md#303560
#
resource "aws_vpc_endpoint" "ssh_s3gateway" {
  vpc_id = aws_vpc.ssh.id

  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  vpc_endpoint_type = "Gateway"
  route_table_ids   = [ aws_route_table.ssh.id ]

  tags = {
    Name               = "S3 Gateway"
    "cost:allocation"  = var.tag_cost_allocation
    "resource:context" = var.tag_resource_context
  }
}

#
# Routing
#
resource "aws_route_table" "ssh" {
  vpc_id = aws_vpc.ssh.id

  tags = {
    Name = "SSH"
  }
}

resource "aws_main_route_table_association" "ssh" {
  vpc_id         = aws_vpc.ssh.id
  route_table_id = aws_route_table.ssh.id
}

#
# Security Groups, because they are circular, so
# define 'em empty, then add the rules
#
resource "aws_security_group" "ec2" {
  name        = "for_ec2"
  description = "Permit HTTPS to & from the VPC Endpoints"
  vpc_id      = aws_vpc.ssh.id

  tags = {
    Name              = "For EC2"
    "cost:allocation" = var.tag_cost_allocation
  }
}

resource "aws_security_group_rule" "ingress_https_from_vpce" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  description = "Inbound from the Interface VPC Endpoints"

  security_group_id        = aws_security_group.ec2.id
  source_security_group_id = aws_security_group.vpce.id
}

resource "aws_security_group_rule" "egress_https_to_vpce" {
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  description = "Outbound to the Interface VPC Endpoints"

  security_group_id        = aws_security_group.ec2.id
  source_security_group_id = aws_security_group.vpce.id
}

resource "aws_security_group_rule" "egress_https_to_s3gateway" {
  type            = "egress"
  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  prefix_list_ids = [ aws_vpc_endpoint.ssh_s3gateway.prefix_list_id ]
  description     = "Outbound to the S3 Gateway VPC Endpoint"

  security_group_id        = aws_security_group.ec2.id
}

resource "aws_security_group" "vpce" {
  name        = "for_vpce"
  description = "Permit HTTPS to & from the EC2 instance"
  vpc_id      = aws_vpc.ssh.id

  tags = {
    Name              = "For VPC Endpoints"
    "cost:allocation" = var.tag_cost_allocation
  }
}

resource "aws_security_group_rule" "ingress_https_from_ec2" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  description = "Inbound from the EC2 instance"

  security_group_id        = aws_security_group.vpce.id
  source_security_group_id = aws_security_group.ec2.id
}

resource "aws_security_group_rule" "egress_https_to_ec2" {
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  description = "Outbound to the EC2 instance"

  security_group_id        = aws_security_group.vpce.id
  source_security_group_id = aws_security_group.ec2.id
}
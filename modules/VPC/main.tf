#
# The VPC will have a single private subnet, no routes in the route table, a security group
# that does not permit traffic and 
#

#
# The 2x CIDR ranges included below were reverse engineered and are
# only included because they are needed to make this demo work...
#
# But why? In a production context, a VPC Endpoint would be used in
# order to enable network connectivity into the private subnet, but
# for the demo, this isn't realistic as it'd also need things like
# a VPN ingress and associated configuration, which isn't realistic
# for the demo, so in order to make it work, but without adding an
# entry like 0.0.0.0/0
#
# From https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-create-vpc.html

# Add to the list as required if required...
#
locals {
  aws_cidr_ranges = ["52.94.48.0/20", "52.95.150.0/24"]
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
# Build the prefix list, see locals above...
#
resource "aws_ec2_managed_prefix_list" "ssh" {
  name           = "AWS Ports for SSM"
  address_family = "IPv4"
  max_entries    = length(local.aws_cidr_ranges)

  dynamic "entry" {
    for_each = local.aws_cidr_ranges
    content {
      cidr = entry.value
      description = "AWS CIDR Range for ssm, ssmmessages & ec2messages"
    }
  }

  tags = {
    Name = "SSH"
  }
}

#
# An Internet Gateway is needed as part of the workaround/hack in relation
# to local.aws_cidr_range, see above...
#
resource "aws_internet_gateway" "ssh" {
  vpc_id = aws_vpc.ssh.id

  tags = {
    Name = "SSH"
  }
}

#
# Routing, again, see the commentary with the local.aws_cidr_range
#
resource "aws_route_table" "ssh" {
  vpc_id = aws_vpc.ssh.id

  dynamic "route" {
    for_each = local.aws_cidr_ranges
    content {
      cidr_block = route.value
      gateway_id = aws_internet_gateway.ssh.id
    }
  }

  tags = {
    Name = "SSH"
  }
}

resource "aws_main_route_table_association" "ssh" {
  vpc_id         = aws_vpc.ssh.id
  route_table_id = aws_route_table.ssh.id
}

#
# For demo purposes, permit absolutely no ingress or egress
#
resource "aws_security_group" "ssh" {
  name        = "allow_nothing"
  description = "Allow no traffic in, and only out to the ssm, ssmmessages & ec2messages endpoints"
  vpc_id      = aws_vpc.ssh.id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    prefix_list_ids = [aws_ec2_managed_prefix_list.ssh.id]
    description = "Outbound only for ssm, ssmmessages & ec2messages"
  }

  tags = {
    Name              = "Allow Nothing"
    "cost:allocation" = var.tag_cost_allocation
  }
}


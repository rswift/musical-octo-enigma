output "vpc_id" {
  value       = aws_vpc.ssh.id
  description = "ID of the VPC"
}

output "private_subnet_id" {
  value       = aws_subnet.private.id
  description = "ID of the private subnet"
}

output "ec2_security_group_id" {
    value       = aws_security_group.ec2.id
    description = "ID of the newly created Security Group for the EC2 instance"
}

output "vpce_security_group_id" {
    value       = aws_security_group.vpce.id
    description = "ID of the newly created Security Group for the VPC Endpoints"
}
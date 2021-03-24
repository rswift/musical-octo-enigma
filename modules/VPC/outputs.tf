output "vpc_id" {
  value       = aws_vpc.ssh.id
  description = "ID of the VPC"
}

output "private_subnet_id" {
  value       = aws_subnet.private.id
  description = "ID of the private subnet"
}

output "security_group_id" {
    value       = aws_security_group.ssh.id
    description = "ID of the newly created Security Group"
}
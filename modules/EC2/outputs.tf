

output "public_ip" {
  value       = aws_instance.ssh.public_ip
  description = "The public IP address of the new EC2 instance - should be empty/invalod"
}

output "ami_id" {
  value       = data.aws_ami.ssh.id
  description = "AMI ID that was used"
}
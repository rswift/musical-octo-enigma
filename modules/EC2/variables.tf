variable "subnet_id" {
  description = "The ID of the subnet to deploy this EC2 instance into"
}

variable "ssh_instance_type" {
  default     = "t2.micro"
  description = "The type of EC2 instance to create - strongly advise not changing this for the SSH access demo!"
}

variable "shutdown_behaviour" {
  default     = "terminate"
  description = "Behaviour with EC2 instance is shut down, one of: stop or terminate"
  validation {
    condition     = can(regex("^(terminate|stop)$", var.shutdown_behaviour))
    error_message = "Terminate behaviour can only be one of 'stop' or 'terminate'!"
  }
}

variable "security_group_id" {
  type        = list(any)
  description = "ID(s) of the Security Group(s) to associate"
}

variable "log_group_name" {
    default     = "/EC2/Sessions"
    description = "Name of the CloudWatch Log Group"
}

#
# Tags
#
variable "tag_Name" {
  default     = "SSH no SSH"
  description = "Friendly name for the VPC"
}
variable "tag_cost_allocation" {
  default     = "work"
  description = "Where costs for the resource should be charged to"
}
variable "tag_resource_context" {
  default     = "sandbox"
  description = "What is this resources for?"
}

#
# AWS Account Number: data.aws_caller_identity.current.account_id
#
data "aws_caller_identity" "current" {}

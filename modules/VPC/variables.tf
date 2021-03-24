#
# Network
#
variable "cidr_block" {
  default     = "10.11.12.0/24"
  description = "The CIDR block to use for the VPC"
}

variable "private_subnet_cidr_block" {
  default     = "10.11.12.0/28"
  description = "The CIDR block to use for the private subnet in the VPC"
}

#
# Tags
#
variable "tag_Name" {
  default     = "SSH without port 22"
  description = "Friendly name for the VPC"
}
variable "tag_cost_allocation" {
  description = "Where costs for the resource should be charged to"
}
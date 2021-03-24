



# Define data items that permit the resolution of the account number and region
#
# https://www.terraform.io/docs/providers/aws/d/caller_identity.html
#
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs#shared-credentials-file
variable "aws_profile" {
  default     = "default"
  description = "The name of the AWS profile to use, as per the shared credentials file"
}

variable "target_account" {
  description = "The AWS account number of the account where the function will be deployed into (via sts:AssumeRole)"
}


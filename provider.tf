#
# This file extracts away some details to help keep things a little more organised
#
# https://www.terraform.io/docs/configuration/terraform.html
# https://www.terraform.io/docs/configuration/version-constraints.html
#
terraform {
  required_version = "~> 0.14.8"

  #
  # This would typically be an S3 bucket or some other highly durable
  # storage to persist the Terraform state. For this purpose, we are using
  # a local store - the state file is JSON.
  #
  # https://www.terraform.io/docs/backends/types/local.html
  # https://www.terraform.io/docs/state/index.html
  #
  backend "local" {
    path = "State/terraform.tfstate"
  }

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#example-usage
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

#
# https://www.terraform.io/docs/providers/aws/index.html
#
provider "aws" {
  profile = var.aws_profile
  region  = "eu-west-2"

  #
  # if you only have one account, then assuming a role is not required
  # as the rest of this configuration deploys via an IAM user... it
  # could use assume role, but that's a more complex configuration than
  # is strictly necessary...
  #
  assume_role {
    role_arn     = "arn:aws:iam::${var.target_account}:role/deploy"
    session_name = "terraform_session"
    external_id  = "franklea_speeking"
  }
}
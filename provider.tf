# =================================================================================
# PROVIDER CONFIGURATION
# =================================================================================
# This file configures the AWS provider, which allows Terraform to interact with
# AWS services. It specifies the required provider version and the default region
# where the resources will be created.
# =================================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}
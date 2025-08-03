# =================================================================================
# VARIABLE DEFINITIONS
# =================================================================================
# This file defines the input variables for our Terraform configuration.
# =================================================================================

variable "aws_region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "us-east-1"
}

variable "create_dns_and_cdn" {
  description = "Set to true if you have a custom domain and want to create Route 53, ACM, CloudFront, and WAF resources."
  type        = bool
  default     = false 
}
#set to true if you want to add a domain name

variable "domain_name" {
  description = "Your custom domain name (e.g., buildownstuff.fun). Only used if create_dns_and_cdn is true."
  type        = string
  default     = "" # Defaults to an empty string
}
#add your domain name here.

variable "notification_email" {
  description = "The email address to send monitoring alerts to."
  type        = string
  default     = "your-email@example.com"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "A list of CIDR blocks for the public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "A list of CIDR blocks for the private subnets."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "instance_type" {
  description = "The EC2 instance type for the application servers."
  type        = string
  default     = "t2.micro"
}

variable "db_instance_class" {
  description = "The instance class for the RDS database."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "The name of the RDS database."
  type        = string
  default     = "fastapidb"
}

variable "db_username" {
  description = "The username for the RDS database."
  type        = string
  default     = "fastapiuser"
  sensitive   = true
}

variable "environment" {
  description = "The name of the AWS environment"
  type        = string
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "subnet_tier" {
  description = "The tier of the subnets"
  type        = string
}

variable "sso_admin_role_name" {
  description = "The name of the SSO admin role"
  type        = string
}

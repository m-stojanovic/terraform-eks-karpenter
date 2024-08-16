# General
variable "aws_account_id" {
  description = "The AWS account number."
  type        = string
}
variable "region" {
  description = "The AWS region where resources will be deployed."
  type        = string
}

variable "aws_profile" {
  description = "The AWS profile."
  type        = string
}

variable "environment" {
  description = "Value to identify the environment."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where resources such as subnets and EC2 instances will be provisioned."
  type        = string
}

variable "private_subnets" {
  description = "A list of private subnet IDs where resources that do not require direct internet access will be located."
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to apply to all resources for resource grouping and cost tracking."
  type        = map(string)
}

# EKS Module
variable "admin_username" {
  description = "The username for the administrator who will have cluster-admin access to the EKS cluster. This username must correspond to an existing IAM user in your AWS account."
  type        = string
}

variable "eks_public_access_cidr" {
  description = "A CIDR block representing the IP range from which it will be allowed to connect to EKS cluster."
  type        = list(string)
}


# Karpenter Module
variable "karpenter_chart_version" {
  description = "Karpenter Helm chart version to be installed"
  type        = string
}

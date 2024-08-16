# General
aws_account_id  = "070496647552"
region          = "us-east-1"
aws_profile     = "local"
environment     = "dev"
vpc_id          = "vpc-ed203397"
private_subnets = ["subnet-04f4a7c617b7a74f7", "subnet-0b10cddd3fb19ee35"]
tags = {
  "org:TechnicalProvisioner" = "terraform"
  "org:Owner"                = "devops"
  "org:Env"                  = "dev"
}

# EKS Module
admin_username         = "mstojanovic"
eks_public_access_cidr = ["0.0.0.0/0"] # adjustable, 0.0.0.0/0 is default. 

# Karpenter Module
karpenter_chart_version = "0.37.0"

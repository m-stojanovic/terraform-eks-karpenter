terraform {
  required_version = ">= 1.6.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.61"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
    }
    # kubectl = {
    #   source  = "gavinbunney/kubectl"
    #   version = "1.14.0"
    # }
  }
}

provider "aws" {
  region = var.region
  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account_id}:role/TerraformDeployment"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    # token                = data.aws_eks_cluster_auth.this.token
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["--profile", "${var.aws_profile}", "eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# provider "kubectl" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#   token                = data.aws_eks_cluster_auth.this.token
#   load_config_file = false
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["--profile", "${var.aws_profile}", "eks", "get-token", "--cluster-name", module.eks.cluster_name]
#   }
# }

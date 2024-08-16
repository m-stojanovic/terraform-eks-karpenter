locals {
  cluster_name = "${var.environment}-eks-cluster"
  access_entries = {
    "rule_1" = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.admin_username}"
      user_name         = "${var.admin_username}"
      policy_associations = {
        "association_1" = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.23.0"

  cluster_version = "1.30"
  cluster_name    = local.cluster_name
  subnet_ids      = var.private_subnets

  tags = var.tags

  vpc_id                          = var.vpc_id
  create_cloudwatch_log_group     = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  # restricting the public access to the vpn cidr 
  cluster_endpoint_public_access_cidrs = var.eks_public_access_cidr
  # allow iam users to access the cluster
  access_entries = local.access_entries
  # karpenter requirements
  node_security_group_tags = {
    "karpenter.sh/discovery" = local.cluster_name
  }

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  eks_managed_node_groups = {
    node = {
      instance_types = ["t3.large"]

      min_size     = 2
      max_size     = 10
      desired_size = 2
    }
  }
}
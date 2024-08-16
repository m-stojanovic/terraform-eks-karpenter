aws_account_id               = "070496647552"
environment                  = "dev"
eks_cluster_name             = "dev-eks-cluster"
karpenter_node_iam_role_name = "Karpenter-dev-eks-cluster"

karpenter_nodepool = {
  "amd64" = {
    name            = "amd64"
    ec2nodeclass    = "default"
    capacity_type   = ["spot"]
    instance_family = ["t3", "m5", "c5"]
    instance_size   = ["large", "xlarge", "2xlarge"]
    topology        = ["us-east-1a", "us-east-1b"]
    architecture    = ["amd64"]
    labels = {
      created_by = "karpenter"
    }
  }
  "graviton" = {
    name            = "graviton"
    ec2nodeclass    = "default"
    capacity_type   = ["spot"]
    instance_family = ["m6g", "c6g", "t4g"]
    instance_size   = ["large", "xlarge", "2xlarge"]
    topology        = ["us-east-1a", "us-east-1b"]
    architecture    = ["arm64"]
    labels = {
      created_by = "karpenter"
    }
  }
}
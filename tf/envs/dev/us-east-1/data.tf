data "aws_caller_identity" "current" {}

data "aws_eks_cluster_auth" "this" {
  name = local.cluster_name
}

data "aws_ecrpublic_authorization_token" "token" {}

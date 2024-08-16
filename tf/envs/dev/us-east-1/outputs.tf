output "eks_cluster_name" {
  description = "The name of the EKS cluster managed by the EKS module."
  value       = module.eks.cluster_name
}

output "karpenter_node_iam_role" {
  description = "The IAM role name used by Karpenter to manage nodes."
  value       = module.karpenter.node_iam_role_name
}

output "aws_account_id" {
  description = "The AWS account ID."
  value       = data.aws_caller_identity.current.account_id
}

output "karpenter_aws_node_instance_profile_name" {
  value = module.karpenter.instance_profile_name
}

output "karpenter_sqs_queue_name" {
  value = module.karpenter.queue_name
}

output "instance_profile_arn" {
  description = "ARN assigned by AWS to the instance profile"
  value       = module.karpenter.instance_profile_arn
}

output "instance_profile_id" {
  description = "Instance profile's ID"
  value       = module.karpenter.instance_profile_id
}

output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = module.karpenter.instance_profile_name
}

output "instance_profile_unique" {
  description = "Stable and unique string identifying the IAM instance profile"
  value       = module.karpenter.instance_profile_unique
}

output "iam_role_arn" {
  description = "Karpenter IAM role"
  value       = module.karpenter.iam_role_arn
}

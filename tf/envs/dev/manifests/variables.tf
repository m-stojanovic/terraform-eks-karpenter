variable "aws_account_id" {
  description = "The AWS account number."
  type        = string
}

variable "environment" {
  description = "Value to identify the environment."
  type        = string
}

variable "eks_cluster_name" {
  description = "The AWS EKS Cluster name that is created from the us-east-1 project."
  type        = string
}

variable "karpenter_node_iam_role_name" {
  description = "The name of the IAM role associated with the Karpenter node instances. This role defines the permissions that the Karpenter nodes have, including actions they can perform within AWS."
  type        = string
}

variable "karpenter_nodepool" {
  type = map(object({
    name            = string
    ec2nodeclass    = string
    capacity_type   = list(string)
    instance_family = list(string)
    instance_size   = list(string)
    topology        = list(string)
    architecture    = list(string)
    labels          = optional(map(string))
    taints = optional(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
}
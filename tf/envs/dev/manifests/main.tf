
locals {
  karpenter_ec2nodeclass_yaml = yamldecode(templatefile("${path.module}/templates/karpenter-ec2nodeclass.yaml.tpl", {
    name             = "default"                        # commented out to simply the testing of the task for the OpsFleet team
    eks_cluster_name = var.eks_cluster_name             # data.terraform_remote_state.main.outputs.eks_cluster_name
    iam_role         = var.karpenter_node_iam_role_name # data.terraform_remote_state.main.outputs.karpenter_node_iam_role
  }))
  karpenter_nodepools_yaml = {
    for key, value in var.karpenter_nodepool :
    key => yamldecode(templatefile("${path.module}/templates/karpenter-nodepool.yaml.tpl", {
      name            = key
      ec2nodeclass    = value.ec2nodeclass
      capacity_type   = value.capacity_type
      instance_family = value.instance_family
      instance_size   = value.instance_size
      topology        = value.topology
      taints          = try(value.taints, null)
      architecture    = value.architecture
      labels = merge(
        value.labels,
        {
          environment = var.environment
        }
      )
    }))
  }
}

resource "kubernetes_manifest" "karpenter_ec2nodeclass" {
  manifest = local.karpenter_ec2nodeclass_yaml
}

resource "kubernetes_manifest" "karpenter_nodepool" {
  for_each = local.karpenter_nodepools_yaml

  manifest = each.value

  depends_on = [kubernetes_manifest.karpenter_ec2nodeclass]
}
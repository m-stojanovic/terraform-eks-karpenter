module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.23.0"

  cluster_name = module.eks.cluster_name

  enable_irsa                     = true
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]
  # karpenter iam controller role
  create_iam_role = true
  iam_role_policies = {
    "Policy_1" = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    "Policy_2" = aws_iam_policy.karpenter_policy_1.arn
  }
  # karpenter iam node role
  create_node_iam_role          = true
  node_iam_role_use_name_prefix = false
  create_access_entry           = true
  node_iam_role_additional_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }
  # remove the prefix from cloudwatch rules
  rule_name_prefix = ""

  tags = var.tags
}

# create the service-linked role for EC2 Spot Instances 
resource "aws_iam_policy" "karpenter_policy_1" {
  name = "karpenter-service-linked-role-ec2-spot-policy"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "iam:CreateServiceLinkedRole",
        ]
        Effect   = "Allow",
        Resource = "*",
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "spot.amazonaws.com"
          }
        },
      }
    ]
  })
}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true
  #wait                = false
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = var.karpenter_chart_version
  
  set {
    name  = "settings.clusterName"
    value = local.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set { # karpenter controller iam role 
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.karpenter.iam_role_arn
  }

  set { # sqs queue from where karpenter is pulling messages delivered by cloudwatch event rules
    name  = "settings.interruptionQueue"
    value = module.karpenter.queue_name
  }

  set {
    name  = "dnsPolicy"
    value = "Default"
  }
}

# Commented out resources due to switch to kubernetes provider
# resource "kubectl_manifest" "karpenter_ec2nodeclass" {
#   yaml_body = templatefile("${path.module}/configs/karpenter-ec2nodeclass.yaml.tpl", {
#     name             = "default"
#     eks_cluster_name = module.eks.cluster_name
#     iam_role         = module.karpenter.node_iam_role_name
#   })
#   # terraform will fails with "failed to fetch resource from kubernetes" 
#   # resource is created successfully, this is just a terraform provider issue
#   # https://github.com/gavinbunney/terraform-provider-kubectl/issues/270
#   depends_on = [helm_release.karpenter] 
# }

# resource "kubectl_manifest" "karpenter_nodepool" {
#   for_each = var.karpenter_nodepool

#   yaml_body = templatefile("${path.module}/configs/karpenter-nodepool.yaml.tpl", {
#     name            = each.key
#     ec2nodeclass    = each.value.ec2nodeclass
#     instance_family = each.value.instance_family
#     instance_size   = each.value.instance_size
#     topology        = each.value.topology
#     taints          = each.value.taints
#     architecture    = each.value.architecture
#     labels = merge(
#       each.value.labels,
#       {
#         environment = var.environment
#       }
#     )
#   })

#   depends_on = [
#     kubectl_manifest.karpenter_ec2nodeclass
#   ]
# }

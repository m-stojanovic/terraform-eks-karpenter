apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: ${name}
spec:
  amiFamily: AL2023
  role: ${iam_role}
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${eks_cluster_name} 
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: ${eks_cluster_name} 
  tags:
    karpenter.sh/discovery: ${eks_cluster_name}
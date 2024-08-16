apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: ${name}
spec:
  template:
    metadata:
%{ if labels != null ~}
      labels:
%{ for k, v in labels ~}
        ${k}: ${v}
%{ endfor ~}
%{ endif ~}
    spec:
      nodeClassRef:
        apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        name: ${ec2nodeclass}
%{ if taints != null ~}
      taints:
        - key: ${taints.key}
          value: ${taints.value}
          effect: ${taints.effect}
%{ endif ~}

      requirements:
        - key: "kubernetes.io/arch"
          operator: In
          values: ${jsonencode(architecture)}
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ${jsonencode(capacity_type)}
        - key: karpenter.k8s.aws/instance-family
          operator: In
          values: ${jsonencode(instance_family)}
          minValues: 3
        - key: karpenter.k8s.aws/instance-size
          operator: In
          values: ${jsonencode(instance_size)}
          minValues: 3
        - key: topology.kubernetes.io/zone
          operator: In
          values: ${jsonencode(topology)}
        - key: "karpenter.k8s.aws/instance-generation"
          operator: Gt
          values: ["2"]

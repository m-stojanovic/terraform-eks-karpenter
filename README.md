# EKS with Karpenter on AWS


## Overview

This repository provides a Terraform setup to deploy Karpenter, an open-source node provisioning tool, into an Amazon EKS cluster. VPC is considered to be already existing. The configuration supports provisioning both x86 (amd64) and ARM (Graviton) instances, offering flexibility for workload scheduling based on architecture.

### Prerequisites

1. __Terraform:__ Ensure you have Terraform installed on your machine. The configuration is tested with Terraform version >= 1.6.5.
2. __AWS CLI:__ Install and configure the latest version of the AWS CLI.
3. __Kubectl:__ Install kubectl and configure it to interact with your EKS cluster.
4. __Configured existing VPC:__ I recommend having VPC Endpoints for ec2, ssm, sqs. This allows resources in the VPC to communicate with AWS services without needing to traverse the internet.

### Configuration

Before running Terraform in the __us-east-1__, it is needed to configure certain variables in the terraform.tfvars. The variables are the following:  

  `aws_account_id:` The AWS account ID.  
  `region:` The AWS region where you want to deploy the resources (e.g., us-east-1).  
  `aws_profile:` The AWS CLI profile to use for deploying resources.  
  `environment:` The environment name (e.g., dev, prod) for tagging and organizing resources.  
  `vpc_id:` The ID of the VPC where the resources will be deployed.  
  `private_subnets:` A list of private subnet IDs in the VPC where the resources will be deployed.  
  `tags:` A map of tags to apply to all resources. 
  `admin_username:` The username for admin access to the resources.  
  `eks_public_access_cidr:`: The CIDR ranges from which connections are allowed to the EKS cluster.
  `karpenter_chart_version:` The version of the Karpenter Helm chart to deploy (e.g., 0.37.0).  

For running Terraform in the __manifests__ directory, you need to configure the following variables in the terraform.tfvars:

  `aws_account_id:` The AWS account ID.  
  `environment:` The environment name (e.g., dev, prod) for tagging and organizing resources.  
  `eks_cluster_name:` The name of the created EKS cluster from the __us-east-1__ directory.  
  `karpenter_node_iam_role_name:` The name of the created IAM role associated with the Karpenter node instances.  
  `karpenter_nodepool:` Define the node pools (x86 and Graviton) with their respective configurations.  

### How to Deploy

1. __Initialize Terraform:__ Run terraform init in the __us-east-1__ project to initialize the working directory containing Terraform configuration files that will deploy EKS and Karpenter.
2. __Plan the Deployment:__ Use a terraform plan to see the changes.
3. __Apply the Configuration:__ Deploy the resources by running terraform apply. This will:
  • Deploy the AWS EKS Cluster module and all necessary related resources.
    - Module reference: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest/examples/eks-managed-node-group
  • Deploy the AWS Karpenter module and prepare the resources for the helm Karpenter chart.
    - Module reference: https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest/examples/karpenter?tab=outputs
  • Deploy the Karpenter Helm chart in your EKS cluster using the helm provider.
    - Chart reference: https://github.com/aws/karpenter-provider-aws/tree/main/charts/karpenter
4. __Connect to the EKS cluster:__ `aws eks --region us-east-1 update-kubeconfig --name dev-eks-cluster --profile ${aws_profile}`
5. __Use the Outputs:__ Extract the values for the eks_cluster_name and karpenter_node_iam_role_name variable in the manifest directory. Values should be same unless the environment parameter is different. 
6. __Initialize Terraform:__ Navigate to the directory __manifests__. Initialize the terraform and apply the deployment. This will: 
  • Set up the EC2NodeClass and NodePools for both amd64 and arm64 architectures using kubernetes_manifest resource from the kubernetes terraform provider.

### Notes: 

The initial approach was to use the kubectl provider and keep everything under the single directory ( __us-east-1__ ). Still, unfortunately, as kubectl provider has the known issue - https://github.com/gavinbunney/terraform-provider-kubectl/issues/270 terraform will fail with "failed to fetch a resource from kubernetes". The resource in the background is created successfully, but the deployment will always fail at that step. The solution was to use the Kubernetes provider. But there we have one important limitation.  
      
"_When using interpolation to pass credentials to the Kubernetes provider from other resources, these resources SHOULD NOT be created in the same Terraform module where Kubernetes provider resources are also used. This will lead to intermittent and unpredictable errors which are hard to debug and diagnose. The root issue lies with the order in which Terraform itself evaluates the provider blocks vs. actual resources._"  

In other words, we can not configure the Kubernetes provider authentication in the same state where the EKS Cluster creation is located. Initialization of the Kubernetes provider will not happen due to missing credentials as the EKS cluster has not been yet created. So the Kubernetes provider had to be separated into the __manifests__ directory. 

### Scheduling Pods on x86 (amd64) or Graviton Instances

Karpenter decides which NodePool to use based on the nodeSelector specified in your pod or deployment YAML. We have 2 NodePools available. Here’s how you can specify whether a pod should run on an x86 or ARM instance.

__Example: Deploying an x86 (amd64) Pod__
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-amd64
spec:
  replicas: 50
  selector:
    matchLabels:
      app: nginx-amd64
  template:
    metadata:
      labels:
        app: nginx-amd64
    spec:
      nodeSelector:
        kubernetes.io/arch: amd64
      containers:
        - name: nginx-amd64
          image: nginxdemos/hello
          imagePullPolicy: Always
          resources:
            requests:
              memory: "512Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "100m"

```

__Example: Deploying an ARM (Graviton) Pod__
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-arm64
spec:
  replicas: 30
  selector:
    matchLabels:
      app: nginx-arm64
  template:
    metadata:
      labels:
        app: nginx-arm64
    spec:
      nodeSelector:
        kubernetes.io/arch: arm64
      containers:
        - name: nginx-arm64
          image: nginx
          imagePullPolicy: Always
          resources:
            requests:
              memory: "32Mi"
              cpu: "10m"
            limits:
              memory: "32Mi"
              cpu: "10m"

```

### How to Validate

1. __Check NodePools and NodeClasses:__ After deploying the Karpenter configuration, use kubectl to verify that the NodePools are correctly set up. Note that EC2NodeClass needs a few minutes to detect the subnets and security group. Once the subnets and security group ids are identified in the output of the ec2nodeclass manifest, these resources are validated. 
      `kubectl -n karpenter get ec2nodeclasses.karpenter.k8s.aws default -o yaml`   
      `kubectl -n karpenter get nodepools.karpenter.sh`

2. __Deploy Pods:__ Apply the deployment YAMLs for x86 and ARM architectures and verify that the pods are scheduled on the correct instance types. From the __manifests__ directory do the following:  
      `kubectl apply -f deployment_amd64.yaml`  
      `kubectl apply -f deployment_arm64.yaml`  

3. __Verify Pods:__ Check that the pods are running on the appropriate architecture by describe the node:  
      `kubectl get pods -o wide` 
      `kubectl describe node ${ip}.ec2.internal | grep 'arch'`

### Troubleshooting

1. __NodePool Selection Issues:__ If pods are not being scheduled on the correct node type, double-check the nodeSelector in your deployment YAML and the requirements section in your NodePool configuration.  
2. __IAM Permissions:__ Ensure that the correct IAM roles are associated with Karpenter, especially if you encounter permissions errors when creating instances.  
3. __Visit the troubleshooting official guide__: https://karpenter.sh/docs/troubleshooting/

### Conclusion

This setup enables flexible and cost-efficient node provisioning within an Amazon EKS cluster using Karpenter, supporting both x86 and ARM instances. By following the guidelines above, developers can easily deploy their workloads to development environment with the architecture that best suits their needs.

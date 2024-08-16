# EKS with Karpenter on AWS


## Overview

This repository provides a Terraform setup to deploy Karpenter, an open-source node provisioning tool, into an Amazon EKS cluster. VPC is considered to be already existing. The configuration supports provisioning both x86 (amd64) and ARM (Graviton) instances, offering flexibility for workload scheduling based on architecture.

### Prerequisites

1. __Terraform:__ Ensure you have Terraform installed on your machine. The configuration is tested with Terraform version >= 1.6.5.
2. __AWS CLI:__ Install and configure the latest version of the AWS CLI.
3. __Kubectl:__ Install kubectl and configure it to interact with your EKS cluster.

### Configuration

Before running Terraform in the us-east-1, you need to configure certain variables in the terraform.tfvars. Below are the variables you should be aware of:

  `aws_account_id:` Your AWS account ID.  
  `region:` The AWS region where you want to deploy the resources (e.g., us-east-1).  
  `aws_profile:` The AWS CLI profile to use for deploying resources.  
  `environment:` The environment name (e.g., dev, prod) for tagging and organizing resources.  
  `vpc_id:` The ID of the VPC where the resources will be deployed.  
  `private_subnets:` A list of private subnet IDs in the VPC where the resources will be deployed.  
  `tags:` A map of tags to apply to all resources. 
  `admin_username:` The username for admin access to the resources.  
  `eks_public_access_cidr:`: The CIDR ranges from which connections are allowed to the EKS cluster.
  `karpenter_chart_version:` The version of the Karpenter Helm chart to deploy (e.g., 0.37.0).  

For running Terraform in the manifests directory, you need to configure the following variables in the terraform.tfvars:

  `aws_account_id:` Your AWS account ID.  
  `environment:` The environment name (e.g., dev, prod) for tagging and organizing resources.  
  `eks_cluster_name:` The name of the created EKS cluster from the us-east-1 directory.  
  `karpenter_node_iam_role_name:` The name of the created IAM role associated with the Karpenter node instances.  
  `karpenter_nodepool:` Define the node pools (x86 and Graviton) with their respective configurations.  

### How to Deploy

1. __Initialize Terraform:__ Run terraform init in the us-east-1 project to initialize the working directory containing Terraform configuration files that will deploy EKS and Karpenter.
2. __Plan the Deployment:__ Use a terraform plan to see the changes.
3. __Apply the Configuration:__ Deploy the resources by running terraform apply. This will:
  • Deploy the AWS EKS Cluster module and all necessary related resources.
  • Deploy the AWS Karpenter module and prepare the resources for the helm Karpenter chart.
  • Deploy the Karpenter Helm chart in your EKS cluster using the helm provider.
4. __Initialize Terraform:__ Navigate to the directory manifests. Initialize the terraform and apply the deployment. This will: 
  • Set up the EC2NodeClass and NodePools for both amd64 and arm64 architectures using Kubernetes manifest from the kubernetes terraform provider.

### Notes: 

The initial approach was to use the kubectl provider and keep everything under the single directory ( us-east-1 ). Still, unfortunately, as kubectl provider has the known issue - https://github.com/gavinbunney/terraform-provider-kubectl/issues/270 terraform will fail with "failed to fetch a resource from kubernetes". The resource in the background is created successfully, but the deployment will always fail at that step. As I didn't want to leave this as it is for the task, the solution was to use the Kubernetes provider. But there we have one important limitation.  
      
"_When using interpolation to pass credentials to the Kubernetes provider from other resources, these resources SHOULD NOT be created in the same Terraform module where Kubernetes provider resources are also used. This will lead to intermittent and unpredictable errors which are hard to debug and diagnose. The root issue lies with the order in which Terraform itself evaluates the provider blocks vs. actual resources._"  

In other words, we can not configure the Kubernetes provider authentication in the same state where the EKS Cluster creation is located. Initialization of the Kubernetes provider will not happen as the EKS cluster has not been yet created. So the Kubernetes provider had to be separated into the manifests directory. 


### Scheduling Pods on x86 (amd64) or Graviton Instances

Karpenter decides which NodePool to use based on the nodeSelector specified in your pod or deployment YAML. Here’s how you can specify whether a pod should run on an x86 or ARM instance.

__Example: Deploying an x86 (amd64) Pod__
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      nodeSelector:
        kubernetes.io/arch: amd64
      containers:
        - name: nginx
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
  name: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      nodeSelector:
        kubernetes.io/arch: arm64
      containers:
        - name: nginx
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

### How to Validate

1. __Check Node Pools:__ After deploying the Karpenter configuration, use kubectl to verify that the NodePools are correctly set up. Note that EC2NodeClass needs a few minutes to detect the subnets and security group.   
      `kubectl -n karpenter get nodepools.karpenter.sh`

2. __Deploy Pods:__ Apply the deployment YAMLs for x86 and ARM architectures and verify that the pods are scheduled on the correct instance types. From the manifests directory do the following:  
      `kubectl apply -f deployment_amd64.yaml`  
      `kubectl apply -f deployment_arm64.yaml`  

3. __Verify Pods:__ Check that the pods are running on the appropriate architecture:  
      `kubectl get pods -o wide` 
      `kubectl describe pod/{pod_name}`


### Troubleshooting

1. __NodePool Selection Issues:__ If pods are not being scheduled on the correct node type, double-check the nodeSelector in your deployment YAML and the requirements section in your NodePool configuration.  
2. __IAM Permissions:__ Ensure that the correct IAM roles are associated with Karpenter, especially if you encounter permissions errors when creating instances.  
3. __Timeouts:__ If resources fail to apply due to timeouts, consider increasing the timeouts in your kubernetes_manifest resource configuration.  



### Conclusion

This setup enables flexible and cost-efficient node provisioning within an Amazon EKS cluster using Karpenter, supporting both x86 and ARM instances. By following the guidelines above, developers can easily deploy their workloads to development environment with the architecture that best suits their needs.

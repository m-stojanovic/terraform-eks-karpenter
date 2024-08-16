# EKS with Karpenter on AWS

## Setup
To set up the EKS Cluster with Karpenter autoscaling:
1. Initialize Terraform:

2. Apply the Terraform configuration:

## Deploying a Pod
To deploy a pod on x86 or Graviton instance:
1. Set your kubectl context to the new cluster:


2. Deploy your application:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
spec:
  containers:
  - name: example-container
    image: nginx
    resources:
      requests:
        cpu: 100m
        memory: 100Mi
      limits:
        cpu: 100m
        memory: 100Mi
    nodeSelector:
      karpenter.sh/capacity-type: ON_DEMAND # Change to GRAVITON if needed


This is a foundational setup and might need adjustments based on specific requirements such as additional security settings, logging, or monitoring.

- map module versions

- explain the purpose of the addons, try search THAANKS or smth and all from above take a deeper look, explain why what is needed, add vpn cidr
- explain user assignment, add it to the terraform as well


resource "aws_eks_access_entry" "node" {
  count = var.create && var.create_access_entry ? 1 : 0

  cluster_name  = var.cluster_name
  principal_arn = var.create_node_iam_role ? aws_iam_role.node[0].arn : var.node_iam_role_arn
  type          = var.access_entry_type

  tags = var.tags

  depends_on = [
    # If we try to add this too quickly, it fails. So .... we wait
    aws_sqs_queue_policy.this,
  ]
}


variable "node_security_group_tags" {
  description = "A map of additional tags to add to the node security group created"
  type        = map(string)
  default     = {}
}


remove the node from tag in the sg and other resources
      ~ tags                   = {
            "Name"                                  = "dev-eks-cluster-node"


explain the usage of the role parameters
  create_node_iam_role = false
  node_iam_role_arn         = module.eks.eks_managed_node_groups["node"].iam_role_arn

  this prevents a new node role to be created, as it has same policies as node-eks-node-group-xxxxx and its connected why create_access_entry = false is not needed, as it exits already the   # module.karpenter.aws_eks_access_entry.node[0] will be created
  + resource "aws_eks_access_entry" "node" {


    ----

add if we are using vpc endpoint we can switch from global to regional by adding this annotation

Also, since we are using a VPC Endpoint for the AWS STS, we need to add an eks.amazonaws.com/sts-regional-endpoints=true annotation to the ServiceAccount that will be created for Karpenter.

However, if you add the annotation to the set as:

set {
  name = "serviceAccount.annotations.eks\\.amazonaws\\.com/sts-regional-endpoints" 
  value = "true"
  type = "string"
}

WHY USE IT?
	•	Purpose: The annotation eks.amazonaws.com/sts-regional-endpoints=true instructs the EKS components (like Karpenter) to use the regional STS endpoints instead of the global STS endpoint.
	•	Impact: By default, when AWS services like IAM roles for service accounts (IRSA) need to communicate with STS, they use the global endpoint (sts.amazonaws.com). This annotation changes the endpoint to the regional one (e.g., sts.us-west-2.amazonaws.com for the US West (Oregon) region). This can lead to reduced latency and keeps all data transfer within the region, which enhances compliance with data residency requirements.

Why Use Regional STS Endpoints?

	1.	Reduced Latency: Accessing a regional endpoint can reduce the latency because the requests do not need to travel outside the region.
	2.	Increased Reliability: Using regional endpoints can increase reliability because it avoids a dependency on the global STS service, which could be affected by issues impacting another region.
	3.	Compliance and Data Residency: For organizations that need to comply with regulations that require data to be handled within specific geographic boundaries, using regional endpoints ensures that all STS token exchanges happen within the regional boundaries.
	•	VPC Endpoint for STS: You mentioned not having deployed a VPC endpoint for STS. Normally, the regional STS endpoint does not require a VPC endpoint to be effective, as it is accessible over the internet. However, setting up a VPC endpoint for STS can further enhance security and network performance by keeping traffic within the AWS network and not exposing it to the public internet.
	•	Deployment without VPC Endpoint: If you have not set up a VPC endpoint for STS, the annotation can still be beneficial for the reasons listed above (latency, reliability, compliance). If you decide later to restrict internet access or ensure that all AWS API traffic stays within your VPC, you might then consider setting up a VPC endpoint for STS.

-----


#   set {
#     name  = "settings.aws.defaultInstanceProfile"
#     value = module.karpenter.instance_profile_name
#   }
	•	An instance profile is an IAM role that EC2 instances can assume to make AWS API requests. Karpenter uses instance profiles to provide the EC2 instances it provisions with the necessary permissions to interact with other AWS services, such as ECR for pulling images or CloudWatch for logging.

Consequences of Not Specifying an Instance Profile:

	•	If no instance profile is specified, the EC2 instances provisioned by Karpenter will not have permissions to perform tasks that require AWS API access. This could lead to issues such as:
	•	Unable to pull container images from private repositories.
	•	Unable to log to AWS CloudWatch.
	•	Problems with accessing additional AWS resources that the applications running on these nodes may require.


  -----



create_pod_identity_association = true
  
Purpose of aws_eks_pod_identity_association to associate with karpentercontroller role

	•	IAM Roles for Service Accounts (IRSA): This feature allows you to associate an AWS IAM role with a Kubernetes service account. This association is crucial for granting specific AWS permissions to the pods that run under the service account without assigning those permissions directly to the EC2 instances on which the pods are running.
	•	Security Best Practices: By using IRSA, you adhere to the principle of least privilege by giving fine-grained AWS permissions only to the specific pods that require them, rather than to all pods running on an EC2 instance.

How It Works

When you enable create_pod_identity_association, you are instructing Terraform to create an association between a Kubernetes service account (karpenter in your case) and an IAM role (arn:aws:iam::070496647552:role/KarpenterController-20240814184509619900000005). Here’s what each attribute means:


#############
Overview

This repository provides a Terraform setup to deploy Karpenter, an open-source node provisioning tool, into an Amazon EKS cluster. VPC is considered to be already existing. The configuration supports provisioning both x86 (amd64) and ARM (Graviton) instances, offering flexibility for workload scheduling based on architecture.

Prerequisites

	1.	Terraform: Ensure you have Terraform installed on your machine. The configuration is tested with Terraform version >= 1.6.5.
	2.	AWS CLI: Install and configure the latest version of the AWS CLI.
	3.	kubectl: Install kubectl and configure it to interact with your EKS cluster.

Configuration

Before running Terraform, you need to configure certain variables in your terraform.tfvars file or pass them directly via the command line. Below are the variables you should be aware of:

  • aws_account_id: 
  • region: 
  • aws_profile: 
  • environment: 
  • vpc_id: 
  • private_subnets: 
  • tags: 
  • admin_username: 
	•	karpenter_chart_version: The version of the Karpenter Helm chart to deploy.
  •	cluster_name: The name of your EKS cluster.
	•	karpenter_nodepool: Define the node pools (x86 and Graviton) with their respective configurations.

How to Deploy

	1.	Initialize Terraform: Run terraform init in the us-east-1 project to initialize the working directory containing Terraform configuration files that will deploy EKS and Karpenter.
	2.	Plan the Deployment: Use terraform plan to see what changes will be made.
	3.	Apply the Configuration: Deploy the resources by running terraform apply. This will:
  • Deploy the AWS EKS Cluster module and all necessary related resources.
  • Deploy the AWS Karpenter module and prepare the resources for the helm karpenter chart.
	•	Deploy the Karpenter Helm chart in your EKS cluster using helm provider.
	4.  Initialize Terraform: Navigate to the directory manifests. Initialize terraform and apply the deployment. This will: 
  •	Set up the EC2NodeClass and NodePools for both amd64 and arm64 architectures using kubernetes manifest from kubernetes terraform provider.

  **NOTES:**
  The initial approach was to use the kubectl provider, and keep everything under the single directory ( us-east-1 ) but unfortunately as kubectl provider has the known issue - https://github.com/gavinbunney/terraform-provider-kubectl/issues/270 terraform will fail with "failed to fetch resource from kubernetes". The resource in background is created successfully, but the deployment will always fail at that step. As I didnt want to leave this as it is for the task, the solution was to use kubernetes provider. But there we have one important limitation
      When using interpolation to pass credentials to the Kubernetes provider from other resources, these resources SHOULD NOT be created in the same Terraform module where Kubernetes provider resources are also used. This will lead to intermittent and unpredictable errors which are hard to debug and diagnose. The root issue lies with the order in which Terraform itself evaluates the provider blocks vs. actual resources. 
  In other words, we can not configure the kubernetes provider authentication in the same state where the EKS Cluster creation is located. Initialization of the kubernetes provider will not happen as the EKS cluster has not been yet created. So the kubernetes provider had to be seperated into the manifests directory. 


Scheduling Pods on x86 (amd64) or Graviton Instances

Karpenter decides which NodePool to use based on the nodeSelector specified in your pod or deployment YAML. Here’s how you can specify whether a pod should run on an x86 or ARM instance.

Example: Deploying an x86 (amd64) Pod

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


Example: Deploying an ARM (Graviton) Pod

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


How to Validate

	1.	Check Node Pools: After deploying the Karpenter configuration, use kubectl to verify that the NodePools are correctly set up:
      kubectl -n karpenter get nodepools.karpenter.sh

  2.	Deploy Pods: Apply the deployment YAMLs for x86 and ARM architectures and verify that the pods are scheduled on the correct instance types.
      kubectl apply -f deployment_amd64.yaml
      kubectl apply -f deployment_arm64.yaml

	3.	Verify Pods: Check that the pods are running on the appropriate architecture:
      kubectl get pods -o wide


  Troubleshooting

	•	NodePool Selection Issues: If pods are not being scheduled on the correct node type, double-check the nodeSelector in your deployment YAML and the requirements section in your NodePool configuration.
	•	IAM Permissions: Ensure that the correct IAM roles are associated with Karpenter, especially if you encounter permissions errors when creating instances.
	•	Timeouts: If resources fail to apply due to timeouts, consider increasing the timeouts in your kubernetes_manifest resource configuration.



Conclusion

This setup enables flexible and cost-efficient node provisioning within an Amazon EKS cluster using Karpenter, supporting both x86 and ARM instances. By following the guidelines above, developers can easily deploy their workloads to development environment with the architecture that best suits their needs.
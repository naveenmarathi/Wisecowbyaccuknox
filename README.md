# Wisecow Application -  Deployment on EKS 

## Overview
"Follow these steps to deploy the Wisecow application on Amazon EKS with HTTPS enabled, using Encrypt certificates and AWS Load Balancer integration."

## Prerequisites
- AWS CLI set up with the necessary permissions
- kubectl installed for Kubernetes management
- eksctl installed to create and manage EKS clusters
- Docker installed for building container images
- A registered domain name
- Domain DNS managed via Route 53.

## Step 1: Build and Push Docker Image

```bash

# Create ECR repository
aws ecr create-repository --repository-name wisecow --region REGION

# Build Docker image
docker build -t wisecow:latest .

# Tag for ECR (replace ACCOUNT-ID and REGION)
docker tag wisecow:latest ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com/wisecow:latest

# Login to ECR
aws ecr get-login-password --region REGION | docker login --username AWS --password-stdin ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com

# Push image
docker push ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com/wisecow:latest
```

## Step 2: Create EKS Cluster

```bash
# eksctl create cluster --name wisecow-1-cluster --region us-east-1 --nodegroup-name wisecow-nodes \
  --node-type t2.medium --nodes 2 --nodes-min 1 --nodes-max 3 --managed

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name wisecow-1-cluster
```

## Step 3: Install AWS Load Balancer Controller

```bash
# Enable IAM OIDC provider for the cluster (required for IAM roles for service accounts)
eksctl utils associate-iam-oidc-provider --region=us-east-1 --cluster=wisecow-1-cluster --approve

# Download and create the IAM policy required by the AWS Load Balancer Controller:
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicyForEKS \
    --policy-document file://iam_policy.json

# Create IAM service account
-Create a Kubernetes service account and attach the IAM policy to it:
eksctl create iamserviceaccount \
  --cluster=wisecow-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::ACCOUNT-ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
Replace ACCOUNT-ID with your actual AWS Account ID.

# Install AWS Load Balancer Controller
Add the EKS Helm chart repo and install the controller:
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=wisecow-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
# Verification:
Once installed, verify the controller is running:
-kubectl get pods -n kube-system

## Step 4: Install cert-manager

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
kubectl apply -f URL : This tells Kubernetes to create/update resources described in the YAML file at the given URL.
What cert-manager is: A Kubernetes tool that automatically manages TLS/SSL certificates for your applications, e.g., getting certificates from Let’s Encrypt and keeping them renewed.
So this command installs cert-manager in your cluster.

# Wait for cert-manager to be ready
kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app=cert-manager --timeout=90s
```

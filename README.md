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

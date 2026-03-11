# Wisecow Application -  Deployment on EKS 

## Overview
"Follow these steps to deploy the Wisecow application on Amazon EKS with HTTPS enabled, using Encrypt certificates and AWS Load Balancer integration."

## 📌 Project documentation link

[https://drive.google.com/file/d/1eIHH3QLHv03tzZ9CzXioiegNx6XAEktp/view?usp=sharing](https://drive.google.com/file/d/1GYYhgZuB3RBkUlCy0i-8Js5ABd2DlfUx/view?usp=sharing)

## Prerequisites
- AWS CLI set up with the necessary permissions
- kubectl installed for Kubernetes management
- eksctl installed to create and manage EKS clusters
- Docker installed for building container images
- A registered domain name
- Domain DNS managed via Route 53.

### Step 1: EC2 Setup
- Launch an Ubuntu instance in your favourite region (eg. region `us-east-1`).
- SSH into the instance from your local machine.

### Step 2: Install AWS CLI v2
``` shell
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip-y
unzip awscliv2.zip
sudo ./aws/install
sudo ./aws/install -i /usr/local/aws-cli -b /usr/local/bin --update
aws configure
AWS Access Key ID:
AWS Secret Access Key:
Default region name:
Default output format:
```

### Step 3: Install Docker
``` shell
sudo apt-get update
sudo apt install docker.io
docker ps
sudo chown $USER /var/run/docker.sock
```

## Step 4: Build and Push Docker Image ECR

```shell

# Create ECR repository
aws ecr create-repository --repository-name wisecow --region REGION

# Build Docker image
docker build -t wisecow-naveen:latest .

# Tag for ECR (replace ACCOUNT-ID and REGION)
docker tag wisecow:latest ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com/wisecow:latest

# Login to ECR
aws ecr get-login-password --region REGION | docker login --username AWS --password-stdin ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com

# Push image
docker push ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com/wisecow:latest
```

### Step 5: Install kubectl
``` shell
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin
kubectl version --short --client
```

### Step 6: Install eksctl
``` shell
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

## Step 7: Setup EKS Cluster

```shell
# eksctl create cluster --name wisecow-cluster --region us-east-1 --nodegroup-name wisecow-nodes \
  --node-type t2.medium --nodes 2 --nodes-min 1 --nodes-max 2 --managed

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name wisecow-cluster
kubectl get nodes
```
### Step 8: Run Manifests
``` shell
kubectl create namespace wisecow
kubectl apply -f .
kubectl delete -f .
```

### Step 9: Install AWS Load Balancer
``` shell
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json
eksctl utils associate-iam-oidc-provider --region=us-east-1 --cluster=wisecow-cluster --approve
eksctl create iamserviceaccount --cluster=wisecow-cluster --namespace=kube-system --name=aws-load-balancer-controller --role-name AmazonEKSLoadBalancerControllerRole --attach-policy-arn=arn:aws:iam::091060535961:policy/AWSLoadBalancerControllerIAMPolicy --approve --region=us-east-1
Replace ACCOUNT-ID with your actual AWS Account ID.
```

### Step 10: Deploy AWS Load Balancer Controller
``` shell
sudo snap install helm --classic
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=wisecow-cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl apply -f full_stack_lb.yaml
```

# Verification:
Once installed, verify the controller is running:
-kubectl get pods -n kube-system

## Step 4: Install cert-manager

```shell
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
kubectl apply -f URL : This tells Kubernetes to create/update resources described in the YAML file at the given URL.
What cert-manager is: A Kubernetes tool that automatically manages TLS/SSL certificates for your applications, e.g., getting certificates from Let’s Encrypt and keeping them renewed.
So this command installs cert-manager in your cluster.

# Wait for cert-manager to be ready
kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app=cert-manager --timeout=90s
```

# Update image in k8s/deployment.yaml
image: ACCOUNT-ID.dkr.ecr.REGION.amazonaws.com/wisecow:latest
imagePullPolicy: Always
```

### Update cert-issuer.yaml
```yaml
# Update email in k8s/cert-issuer.yaml
email: your-email@domain.com
```

### Update ingress.yaml
```yaml
# Update host in k8s/ingress.yaml
- host: naveenmarathi.xyz
```

## Step 5: Deploy Application

```bash
# Apply cert-manager issuer
kubectl apply -f k8s/cert-issuer.yaml

# Deploy application
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment/wisecow-deployment

# Apply ingress (this will create ALB)
kubectl apply -f k8s/ingress.yaml
```

## Step 6: Configure DNS

```bash
# Get ALB hostname
kubectl get ingress wisecow-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Create A record pointing naveenmarathi.xyz to ALB hostname
# Or update your DNS provider to point to the ALB
```

## Step 7: Verify Deployment

```bash
# Check all resources
kubectl get all,ingress,certificate

# Check certificate status
kubectl describe certificate wisecow-tls

# Test application
curl https://naveenmarathi.xyz
```

## Troubleshooting

### Check pod logs
```bash
kubectl logs -l app=wisecow
```

### Check ingress events
```bash
kubectl describe ingress wisecow-ingress
```

### Check certificate issues
```bash
kubectl describe certificate wisecow-tls
kubectl describe certificaterequest
```

### Check ALB controller logs
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

## Cleanup

```bash
# Delete application
kubectl delete -f k8s/

# Delete EKS cluster
eksctl delete cluster --name wisecow-cluster --region us-west-2
```

## Important Notes

1. **Replace placeholders:**
   - `ACCOUNT-ID`: Your AWS account ID
   - `REGION`: Your AWS region
   - `naveenmarathi.xyz`: Your domain name
   - `your-email@domain.com`: Your email for Let's Encrypt

2. **Security Groups:** Ensure ALB security group allows HTTP (80) and HTTPS (443) traffic

3. **Domain Validation:** Let's Encrypt requires domain to be publicly accessible for HTTP-01 challenge

4. **Costs:** EKS cluster and ALB incur AWS charges

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
 eksctl create cluster --name wisecow-cluster --region us-east-1 --nodegroup-name wisecow-nodes \
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

### Step 9: Install NGINX Ingress Controller 
``` shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml.
# Wait 1–2 minutes.
kubectl get pods -n ingress-nginx
```

### Step 10: Get AWS LoadBalancer Address
``` shell
kubectl get svc -n ingress-nginx
# You will see something like:
# ingress-nginx-controller   LoadBalancer
# Example external address:a24a963e5a0f34ffc9b255609a14c5e0.elb.us-east-1.amazonaws.com
# Copy this. You will use it in the ingress file.
```

# Verification:
Once installed, verify the controller is running:
-kubectl get pods -n kube-system
```

### Step 11: Install cert-manager 
```shell
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
# Check
kubectl get pods -n cert-manager
# You should see:
cert-manager
cert-manager-webhook
cert-manager-cainjector
```

# Wait for cert-manager to be ready
kubectl wait --namespace cert-manager --for=condition=ready pod --selector=app=cert-manager --timeout=90s
```

### Step 12: Update cert-issuer.yaml
# Apply
kubectl apply -f clusterissuer.yaml-issuer.yaml
# Verify
kubectl get clusterissuer
```yaml

### Step 13: Create Ingress (HTTPS)
# Replace <ELB-DNS> with your load balancer DNS.
``` shell
kubectl apply -f ingress.yaml
```yaml

### Step 14: Verify Certificate
``` shell
kubectl get certificate -n wisecow
# Check secret:
``` shell
kubectl get secret -n wisecow
# You should see:
wisecow-tls
```yaml

### Steps 15: Open in Browser
#Example:
https://a24a963e5a0f34ffc9b255609a14c5e0.elb.us-east-1.amazonaws.com
# Browser will Show:
⚠ Your connection is not private
#Click:
Advanced → Proceed

###  Final Architecture (Wisecow Assignment)

Browser
   │
HTTPS
   │
AWS ELB
   │
NGINX Ingress
   │
Service
   │
Wisecow Pod

# Update host in k8s/ingress.yaml
- host: naveenmarathi.xyz
```yaml

### Step 16: Configure DNS

```Shell
# Get ALB hostname
kubectl get ingress wisecow-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Create A record pointing naveenmarathi.xyz to ALB hostname
# Or update your DNS provider to point to the ALB
```yaml

## Cleanup

```shell
# Delete application
kubectl delete -f k8s/

# Delete EKS cluster
eksctl delete cluster --name wisecow-cluster --region us-east-1
```

## Important Notes

1. **Replace placeholders:**
   - `ACCOUNT-ID`: Your AWS account ID
   - `REGION`: Your AWS region
   - `naveenmarathi.xyz`: Your domain name
 
2. **Security Groups:** Ensure ALB security group allows HTTP (80) and HTTPS (443) traffic

3. **Costs:** EKS cluster and ALB incur AWS charges

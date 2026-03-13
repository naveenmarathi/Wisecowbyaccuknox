# 🐄 Wisecow Application – DevOps CI/CD Deployment on Kubernetes (EKS)

![Docker](https://img.shields.io/badge/Docker-Container-blue)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Orchestration-326ce5)
![AWS](https://img.shields.io/badge/AWS-EKS-orange)
![CI/CD](https://img.shields.io/badge/GitHub%20Actions-CI/CD-black)
![License](https://img.shields.io/badge/License-MIT-green)

A **modern DevOps demonstration project** that deploys the classic **Wisecow application** using a complete **CI/CD pipeline on Kubernetes (Amazon EKS)**.

The project demonstrates **containerization, CI/CD automation, Kubernetes deployment, TLS security, and cloud infrastructure provisioning**.

---
## 🎥 Demo Video

[![Watch the Demo](https://img.shields.io/badge/Watch-Demo_Video-blue?style=for-the-badge)](https://drive.google.com/file/d/1Pdiu1YHOJAym9yLOcBEg1f2F7twUcRAW/view?usp=drive_link)

# 📌 Project Overview

The **Wisecow application** is a simple web server that displays a random fortune message generated using `fortune` and `cowsay`.

This project demonstrates how to deploy it using **modern DevOps practices**.

### Key DevOps Concepts Demonstrated

- Containerization with **Docker**
- Image storage in **Amazon ECR**
- Automated pipeline using **GitHub Actions**
- Container orchestration with **Kubernetes**
- Managed Kubernetes using **Amazon EKS**
- Ingress routing with **NGINX Ingress Controller**
- TLS security using **cert-manager**
- HTTPS access through **AWS Load Balancer**

---

# 🏗 Architecture

```
Browser
   │
 HTTPS
   │
AWS LoadBalancer (ELB)
   │
NGINX Ingress Controller
   │
Kubernetes Service
   │
Wisecow Pod
   │
Docker Container
```

---

# ⚙ Tech Stack

| Technology | Purpose |
|------------|--------|
| Docker | Containerization |
| Amazon ECR | Container Registry |
| Kubernetes | Container Orchestration |
| Amazon EKS | Managed Kubernetes |
| GitHub Actions | CI/CD Automation |
| NGINX Ingress | Traffic Routing |
| Cert Manager | SSL Certificate Management |
| AWS CLI | Cloud Resource Management |

---

# 📂 Project Structure

```
wisecow-devops-project
│
├── wisecow.sh
├── Dockerfile
│
├── k8s
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── clusterissuer.yaml
│
├── .github
│   └── workflows
│        └── deploy.yaml
│
└── README.md
```

---

# 🚀 Deployment Guide

## 1️⃣ Launch EC2 Instance

Launch an **Ubuntu EC2 instance** in your preferred region.

Example:

```
Region: us-east-1
Instance type: t2.medium
```

Connect using SSH:

```bash
ssh ubuntu@your-ec2-ip
```

---

# 🧰 Install Required Tools

## Install AWS CLI

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip -y
unzip awscliv2.zip
sudo ./aws/install
```

Configure credentials:

```bash
aws configure
```

---

## Install Docker

```bash
sudo apt update
sudo apt install docker.io -y
sudo chown $USER /var/run/docker.sock
docker ps
```

---

## Install kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl
sudo mv kubectl /usr/local/bin
kubectl version --client
```

---

## Install eksctl

```bash
curl --silent --location \
"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
| tar xz -C /tmp

sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

---

# ☸ Create EKS Cluster

```bash
eksctl create cluster \
--name wisecow-cluster \
--region us-east-1 \
--nodegroup-name wisecow-nodes \
--node-type t2.medium \
--nodes 2 \
--nodes-min 1 \
--nodes-max 2 \
--managed
```

Update kubeconfig:

```bash
aws eks update-kubeconfig \
--region us-east-1 \
--name wisecow-cluster
```

Verify nodes:

```bash
kubectl get nodes
```

---

# 🐳 Build and Push Docker Image

Create ECR repository:

```bash
aws ecr create-repository \
--repository-name wisecow \
--region us-east-1
```

Build Docker image:

```bash
docker build -t wisecow .
```

Tag image:

```bash
docker tag wisecow:latest \
ACCOUNT-ID.dkr.ecr.us-east-1.amazonaws.com/wisecow:latest
```

Login to ECR:

```bash
aws ecr get-login-password --region us-east-1 \
| docker login --username AWS --password-stdin \
ACCOUNT-ID.dkr.ecr.us-east-1.amazonaws.com
```

Push image:

```bash
docker push ACCOUNT-ID.dkr.ecr.us-east-1.amazonaws.com/wisecow:latest
```

---

# 📦 Deploy Application

Create namespace:

```bash
kubectl create namespace wisecow
```

Deploy resources:

```bash
kubectl apply -f k8s/
```

Verify pods:

```bash
kubectl get pods -n wisecow
```

---

# 🌐 Install NGINX Ingress

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml
```

Check status:

```bash
kubectl get pods -n ingress-nginx
```

---

# 🔒 Install Cert Manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
```

Verify:

```bash
kubectl get pods -n cert-manager
```

---

# 🌍 Configure Ingress

Apply ingress configuration:

```bash
kubectl apply -f k8s/ingress.yaml
```

Get LoadBalancer address:

```bash
kubectl get svc -n ingress-nginx
```

Example:

```
a24a963e5a0f34ffc9b255609a14c5e0.elb.us-east-1.amazonaws.com
```

Open in browser:

```
https://<LoadBalancer-DNS>
```

---

# ⚡ CI/CD Pipeline

Pipeline workflow:

```
Developer Push Code
        │
        ▼
GitHub Actions Pipeline
        │
        ▼
Build Docker Image
        │
        ▼
Push Image to Amazon ECR
        │
        ▼
Deploy to Amazon EKS
```

---

# 🧹 Cleanup Resources

Delete application:

```bash
kubectl delete -f k8s/
```

Delete EKS cluster:

```bash
eksctl delete cluster --name wisecow-cluster --region us-east-1
```

---

# ⚠ Important Notes

Replace placeholders:

| Placeholder | Description |
|-------------|------------|
| ACCOUNT-ID | Your AWS account ID |
| REGION | AWS region |
| DOMAIN | Your registered domain |

Ensure security groups allow:

```
HTTP  (80)
HTTPS (443)
```

---

# 🎯 Key Learning Outcomes

This project demonstrates the ability to:

- Build containerized applications
- Implement CI/CD pipelines
- Deploy applications on Kubernetes
- Manage cloud infrastructure
- Configure secure HTTPS ingress
- Operate production-like DevOps environments

---

# 👨‍💻 **Naveen Marathi**

DevOps Engineer | Cloud | Kubernetes | CI/CD

---

⭐ If you found this project useful, consider giving it a **star on GitHub**.

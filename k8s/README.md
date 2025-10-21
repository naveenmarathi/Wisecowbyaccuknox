# Wisecow Application -  Deployment on EKS 

## Overview
"steps to deploy the Wisecow application on Amazon EKS with HTTPS enabled, using Encrypt certificates and AWS Load Balancer integration."

## Tasks Completed

# 1.Dockerization 
- Created Dockerfile
- Installed required packages: fortune, cowsay, netcat-openbsd

# 2.Kubernetes Deployment 
# Create Namespace
- kubectl apply -f k8s/namespace.yaml
# Deploy Service
- kubectl apply -f k8s/service.yaml
# Deploy Ingress
- kubectl apply -f k8s/ingress.yaml
# Build & Push Docker Image
- docker build -t wisecow-naveen .
docker tag wisecow-naveen:latest wisecow:latest
docker push wisecow:latest
# Deploy Application
kubectl apply -f k8s/
# Verify Deployment
kubectl get pods,svc,ingress -n wisecow

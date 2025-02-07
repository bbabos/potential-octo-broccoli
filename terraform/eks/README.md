# EKS Cluster with Karpenter

This repository contains Terraform configurations for deploying an EKS cluster with Karpenter autoscaling support and various AWS services integration.

## Prerequisites

- AWS CLI configured
- Terraform >= 1.10.0
- kubectl
- helm

## Features

- EKS Cluster (v1.32)
- Karpenter Autoscaling
- EKS Add-ons:
  - CoreDNS
  - kube-proxy
  - VPC CNI
  - EBS CSI Driver
  - Metrics Server
  - Pod Identity Agent
- Managed Node Groups
  - Core Services Node Group
  - Karpenter Controller Node Group

## Deployment Steps

1. Initialize Terraform:

```bash
terraform init
```

2. Apply the configuration:

```bash
terraform apply
```

3. Configure kubectl:

```bash
aws eks update-kubeconfig --name some-cool-cluster --region <your-region>
```

4. Verify Karpenter installation:

```bash
kubectl get pods -n karpenter
```

## Node Groups

### Core Services Node Group

- Instance type: t3.medium
- Min size: 1
- Max size: 3
- Desired size: 2

### Karpenter Controller Node Group

- Instance type: t3.medium
- Min size: 1
- Max size: 3
- Desired size: 2
- Special labels and taints for Karpenter controller

## Karpenter Configuration

### Node Requirements

- Instance categories: c, m, r
- CPU options: 4, 8, 16
- Hypervisor: nitro
- Instance generation: > 5
- Architecture: AMD64 and ARM64
- Capacity types: spot and on-demand

## Running Workloads on Specific Architectures

### For x86_64 (AMD64) Instances:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-amd64
spec:
  replicas: 1
  template:
    spec:
      nodeSelector:
        kubernetes.io/arch: amd64
      containers:
        - name: app
          image: your-image:tag
```

### For ARM64 (Graviton) Instances:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-arm64
spec:
  replicas: 1
  template:
    spec:
      nodeSelector:
        kubernetes.io/arch: arm64
      containers:
        - name: app
          image: your-image:tag
```

## Testing Karpenter Autoscaling

1. Apply the test deployment:

```bash
kubectl apply -f terraform/eks/testing/karpenter-scaling.yaml
```

2. Scale the deployment:

```bash
kubectl scale deployment inflate --replicas=10
```

3. Watch Karpenter create new nodes:

```bash
kubectl get nodes -w
```

## Security Features

- Private cluster endpoint
- VPN access control
- Node security group rules for VPC communication
- EBS volume encryption
- IAM roles with least privilege

#  EKS Terraform Infrastructure


## Mục lục

- [Kiến trúc hệ thống](#-kiến-trúc-hệ-thống)
- [Yêu cầu cài đặt](#-yêu-cầu-cài-đặt)
- [Cấu trúc thư mục](#-cấu-trúc-thư-mục)
- [Hướng dẫn triển khai](#-hướng-dẫn-triển-khai)
- [Truy cập các dịch vụ](#-truy-cập-các-dịch-vụ)
- [Quản lý và vận hành](#-quản-lý-và-vận-hành)
- [Xử lý sự cố](#-xử-lý-sự-cố)
- [Cleanup](#-cleanup)

---

## 🏗️ Kiến trúc hệ thống

### Thành phần chính

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                            │
│  ┌────────────────────────────────────────────────────┐     │
│  │  VPC (10.0.0.0/16)                                 │     │
│  │  ┌──────────────────┐  ┌──────────────────┐       │     │
│  │  │ Private Subnet 1 │  │ Private Subnet 2 │       │     │
│  │  │                  │  │                  │       │     │
│  │  │  ┌────────────┐  │  │  ┌────────────┐ │       │     │
│  │  │  │ EKS Nodes  │  │  │  │ EKS Nodes  │ │       │     │
│  │  │  └────────────┘  │  │  └────────────┘ │       │     │
│  │  └──────────────────┘  └──────────────────┘       │     │
│  │                                                     │     │
│  │  ┌─────────────────────────────────────────┐      │     │
│  │  │ EKS Control Plane (Managed by AWS)      │      │     │
│  │  └─────────────────────────────────────────┘      │     │
│  └────────────────────────────────────────────────────┘     │
│                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────┐      │
│  │ EFS FileSystem │  │ RDS Database   │  │ S3 State │      │
│  └────────────────┘  └────────────────┘  └──────────┘      │
└─────────────────────────────────────────────────────────────┘

Kubernetes Workloads:
├── ArgoCD (GitOps)
├── Jenkins (CI/CD)
├── Vault (Secrets Management)
├── SonarQube (Code Quality)
└── Applications
```

### Infrastructure Modules

- **Network**: VPC, Subnets, Route Tables, NAT Gateway
- **Security Groups**: EKS Cluster, Nodes, RDS, EFS
- **IAM**: Roles và Policies cho EKS Cluster và Nodes
- **EKS**: Kubernetes Cluster với Auto-scaling Node Groups
- **Database**: RDS PostgreSQL (nếu cần)
- **EFS**: Shared storage cho Jenkins cache
- **KeyPair**: SSH access cho worker nodes

---

## 🔧 Yêu cầu cài đặt

### 1. Prerequisites

Cài đặt các công cụ sau trên máy local:

```bash
# Terraform (>= 1.5.0)
choco install terraform  # Windows
# hoặc brew install terraform  # macOS

# AWS CLI
choco install awscli

# kubectl
choco install kubernetes-cli

# Helm (>= 3.0)
choco install kubernetes-helm

# Git
choco install git

# Git Bash (Windows - bắt buộc cho post-install script)
# Download từ: https://git-scm.com/downloads
```

### 2. Cấu hình AWS

```bash
# Cấu hình AWS credentials
aws configure

# Nhập thông tin:
AWS Access Key ID: [YOUR_ACCESS_KEY]
AWS Secret Access Key: [YOUR_SECRET_KEY]
Default region name: ap-southeast-1
Default output format: json
```

### 3. Kiểm tra cài đặt

```bash
terraform --version
aws --version
kubectl version --client
helm version
git --version
```

---

## 📁 Cấu trúc thư mục

```
terraform/
├── environments/           # Cấu hình cho từng môi trường
│   ├── dev/               # Development environment
│   │   ├── main.tf        # Main configuration
│   │   ├── variable.tf    # Variable definitions
│   │   ├── terraform.tfvars  # Variable values
│   │   └── output.tf      # Output values
│   └── prod/              # Production environment
│       ├── main.tf
│       ├── variable.tf
│       ├── terraform.tfvars
│       └── output.tf
├── modules/               # Terraform modules
│   ├── network/          # VPC, Subnets, NAT Gateway
│   ├── security-groups/  # Security Groups
│   ├── iam/              # IAM Roles & Policies
│   ├── eks/              # EKS Cluster & Node Groups
│   ├── database/         # RDS Database
│   ├── efs/              # EFS FileSystem
│   └── keypair/          # EC2 KeyPair
├── scripts/              # Automation scripts
│   └── post_eks_install.sh  # Post-installation script
├── efs-sc.yaml           # EFS StorageClass manifest
└── Jenkinsfile           # Jenkins Pipeline
```

---

##  Hướng dẫn triển khai

### Bước 1: Clone Repository

```bash
git clone https://github.com/MeetingTeam/terraform.git
cd terraform
```

### Bước 2: Triển khai Development Environment

```bash
# Di chuyển vào thư mục dev
cd environments/dev

# Review và chỉnh sửa terraform.tfvars nếu cần
# vim terraform.tfvars

# Khởi tạo Terraform (download providers và modules)
terraform init

# Xem preview các thay đổi
terraform plan

# Triển khai infrastructure (Thời gian: ~15-20 phút)
terraform apply
# Nhập 'yes' để confirm
```

### Bước 3: Post-Installation (Tự động)

Sau khi `terraform apply` hoàn tất, script `post_eks_install.sh` sẽ **tự động chạy** và thực hiện:

1. Cấu hình kubectl để kết nối cluster
2. Clone k8s-repo (ArgoCD manifests)
3. Tạo EFS PersistentVolume cho Jenkins
4. Cài đặt ArgoCD qua Helm
5. Deploy ArgoCD Applications

**Lưu ý**: Script chỉ chạy trên máy local (không chạy trong CI/CD container).

### Bước 4: Cấu hình kubectl (Nếu cần manual)

```bash
# Mở Git Bash
aws eks update-kubeconfig --name doan-cluster-dev --region ap-southeast-1

# Verify connection
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

### Bước 5: Triển khai Production (Tùy chọn)

```bash
cd ../prod
terraform init
terraform plan
terraform apply
```

---

## 🌐 Truy cập các dịch vụ

### 1. ArgoCD (GitOps Dashboard)

```bash
# Port-forward ArgoCD service
kubectl port-forward svc/argocd-server 30081:80 -n argo

# Lấy password admin
kubectl -n argo get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Truy cập: http://localhost:30081
# Username: admin
# Password: [output từ lệnh trên]
```

### 2. Jenkins (CI/CD)

```bash
# Port-forward Jenkins service
kubectl port-forward svc/jenkins 30808:8080 -n jenkins

# Lấy password admin
kubectl -n jenkins get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 -d && echo

# Truy cập: http://localhost:30808
# Username: admin
# Password: [output từ lệnh trên]
```

#### Cấu hình Jenkins

**1. Cài đặt Plugins:**
- Kubernetes
- Pipeline
- Git
- Configuration as Code Plugin
- SonarQube Scanner
- GitHub Branch Source
- Generic Webhook Trigger

**2. Cấu hình Credentials:**

Vào: `Jenkins → Manage Jenkins → Credentials → System → Global credentials`

Thêm các credentials sau:

| ID | Type | Description |
|----|------|-------------|
| `aws-credentials` | AWS Credentials | AWS Access Key & Secret Key |
| `github-token` | Secret text | GitHub Personal Access Token |
| `dockerhub-credentials` | Username/Password | DockerHub login |

**3. Cấu hình Pipeline:**

Tạo Pipeline job mới:
- **Name**: `terraform-pipeline`
- **Type**: Pipeline
- **Pipeline script from SCM**:
  - SCM: Git
  - Repository URL: `https://github.com/MeetingTeam/terraform`
  - Script Path: `Jenkinsfile`
- **Parameterized**:
  - Choice Parameter: `ENV` → `dev`, `prod`
- **Build Triggers**:
  - GitHub hook trigger for GITScm polling

### 3. Vault (Secrets Management)

```bash
# Copy vault files vào pod
kubectl -n vault cp ./vault-config/. vault-0:/home/vault

# Exec vào vault pod
kubectl exec -it vault-0 -n vault -- sh

# Initialize vault (chỉ làm 1 lần)
vault operator init

# Lưu lại Unseal Keys và Root Token!!!
# Unseal Key 1: [SAVE_THIS]
# Unseal Key 2: [SAVE_THIS]
# Unseal Key 3: [SAVE_THIS]
# Unseal Key 4: [SAVE_THIS]
# Unseal Key 5: [SAVE_THIS]
# Initial Root Token: [SAVE_THIS]

# Unseal vault (cần 3/5 keys)
vault operator unseal [KEY_1]
vault operator unseal [KEY_2]
vault operator unseal [KEY_3]
```

### 4. SonarQube (Code Quality)

```bash
# Port-forward SonarQube service
kubectl port-forward svc/sonarqube 30809:9000 -n sonarqube

# Truy cập: http://localhost:30809
# Default credentials:
# Username: admin
# Password: admin (phải đổi password lần đầu)
```

---

## 🔐 Quản lý Secrets

### Apply k8s-repo credentials

```bash
# Tạo secret để ArgoCD pull từ private repo
kubectl apply -f k8s-repo-credentials.yaml
```

### Cấu hình AWS Credentials trong Jenkins

```bash
# Sử dụng Jenkins UI hoặc Jenkins Configuration as Code
# Credentials ID phải khớp với Jenkinsfile:
- awsAccessKeyId
- awsSecretAccessKey
```

---

## 📊 Quản lý và vận hành

### Monitoring

```bash
# Xem logs của pods
kubectl logs -f <pod-name> -n <namespace>

# Xem tất cả pods
kubectl get pods --all-namespaces

# Xem events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Xem resource usage
kubectl top nodes
kubectl top pods -n <namespace>
```


##  Xử lý sự cố

### Pod không start

```bash
# Describe pod để xem lỗi
kubectl describe pod <pod-name> -n <namespace>

# Xem logs
kubectl logs <pod-name> -n <namespace>

# Xem events
kubectl get events -n <namespace>
```


## 🧹 Cleanup

### ⚠️ QUAN TRỌNG: Cleanup trước khi destroy

**Bước 1: Xóa Kubernetes resources**

```bash
# Xóa tất cả applications trong ArgoCD
argocd app delete --all -y

# Hoặc qua kubectl
kubectl delete all --all -n <namespace>

# Xóa PVC (để release EFS/EBS)
kubectl delete pvc --all --all-namespaces
```

**Bước 2: Xóa AWS Load Balancers (BẮT BUỘC)**

```bash
# List tất cả load balancers được tạo bởi EKS
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(LoadBalancerName, `k8s`)].LoadBalancerArn' \
  --output table

# Xóa từng load balancer
aws elbv2 delete-load-balancer --load-balancer-arn <arn>

# Xóa target groups
aws elbv2 describe-target-groups \
  --query 'TargetGroups[?contains(TargetGroupName, `k8s`)].TargetGroupArn' \
  --output table

aws elbv2 delete-target-group --target-group-arn <arn>
```

**Bước 3: Terraform Destroy**

```bash
cd environments/dev

# Preview destroy
terraform plan -destroy

# Destroy infrastructure
terraform destroy
# Nhập 'yes' để confirm

# Nếu gặp lỗi, thử force destroy
terraform destroy -auto-approve

# Hoặc destroy từng resource cụ thể
terraform destroy -target=module.eks
terraform destroy -target=module.database
```

**Bước 4: Manual cleanup (nếu cần)**

```bash
# Xóa S3 state bucket (cẩn thận!)
aws s3 rb s3://nt548-terraform-state-dev --force

# Xóa DynamoDB lock table
aws dynamodb delete-table --table-name nt548-terraform-lock-dev

# Verify VPC đã xóa
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*eks*"
```






**⭐ Nếu dự án hữu ích, hãy cho một star!**

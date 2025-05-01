#!/bin/bash

# Lấy tham số đầu vào
CLUSTER_NAME=$1
REGION=$2
ENV=$3

echo "Starting post-installation for cluster ${CLUSTER_NAME}-${ENV} in region ${REGION}"

# Cấu hình kubectl để kết nối đến cluster
echo "Configuring kubectl to connect to ${CLUSTER_NAME}-${ENV} cluster"
aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}-${ENV}

# Đảm bảo kubectl đã được cấu hình đúng
kubectl cluster-info

# Tạo thư mục làm việc theo cách tương thích với Git Bash
WORK_DIR=$(mktemp -d -p /tmp eks-post-install.XXXXXX)
echo "Working directory: ${WORK_DIR}"
cd "${WORK_DIR}" || exit 1

# Clone repository
echo "Cloning k8s-repo repository"
git clone https://github.com/MeetingTeam/k8s-repo.git --branch main
cd k8s-repo/opensource || exit 1

# Cài đặt Nginx Ingress
echo "Installing Nginx Ingress"
kubectl create ns ingress-nginx || echo "Namespace ingress-nginx already exists"
helm install ingress-nginx ingress-nginx -f ingress-nginx/values.dev.yaml -n ingress-nginx --create-namespace

# Kiểm tra trạng thái Nginx Ingress
echo "Checking Nginx Ingress status"
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Cài đặt Jenkins
echo "Installing Jenkins"
kubectl create ns jenkins || echo "Namespace jenkins already exists"
helm install jenkins jenkins -f jenkins/values.custom.yaml -n jenkins --create-namespace

# Kiểm tra trạng thái Jenkins
echo "Checking Jenkins status"
kubectl get pods -n jenkins
kubectl get svc -n jenkins

# Cài đặt Vault
echo "Installing Vault"
kubectl create ns vault || echo "Namespace vault already exists"
helm install vault vault -f vault/values.custom.yaml -n vault --create-namespace

# ArgoCD
kubectl create ns argo
helm install argocd argo-cd -f argo-cd/values.custom.yaml -n argo

# Rabbitmq
helm install rabbitmq rabbitmq -f rabbitmq/values.custom.yaml



# Kiểm tra trạng thái Vault
echo "Checking Vault status"
kubectl get pods -n vault
kubectl get svc -n vault

# Dọn dẹp thư mục tạm
cd /tmp || exit 1
rm -rf "${WORK_DIR}"

echo "Post-installation completed successfully"
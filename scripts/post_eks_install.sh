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

# Chỉ cấu hình EFS và Jenkins trong môi trường dev
if [ "${ENV}" == "dev" ]; then
  # Lấy EFS ID từ output của terraform
  export EFS_ID=$(terraform -chdir=${WORK_DIR}/../../environments/${ENV} output -raw jenkins_efs_id 2>/dev/null || echo "")

  if [ -n "$EFS_ID" ]; then
    echo "Configuring EFS StorageClass with ID: ${EFS_ID}"
    
    # Tạo StorageClass sử dụng EFS
    cat <<EOF > ${WORK_DIR}/efs-sc.yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: fs-01c6b682f204b8176
  directoryPerms: "700"
EOF

    kubectl apply -f ${WORK_DIR}/efs-sc.yaml
    echo "EFS StorageClass created successfully"
  else
    echo "EFS ID not found in terraform outputs, skipping StorageClass creation"
  fi
  
  # Cài đặt Jenkins trong môi trường dev
  echo "Installing/Upgrading Jenkins in DEV environment"
  kubectl create ns jenkins 2>/dev/null || echo "Namespace jenkins already exists"
  helm upgrade --install jenkins jenkins -f jenkins/values.custom.yaml -n jenkins --create-namespace
fi

# Các cài đặt chung cho mọi môi trường
echo "Installing/Upgrading Nginx Ingress"
kubectl create ns ingress-nginx 2>/dev/null || echo "Namespace ingress-nginx already exists"
helm upgrade --install ingress-nginx ingress-nginx -f ingress-nginx/values.dev.yaml -n ingress-nginx --create-namespace

# Chỉ cài đặt Jenkins ở môi trường dev, đã được xử lý ở trên

echo "Installing/Upgrading Vault"
kubectl create ns vault 2>/dev/null || echo "Namespace vault already exists"
helm upgrade --install vault vault -f vault/values.custom.yaml -n vault --create-namespace

echo "Installing/Upgrading ArgoCD"
kubectl create ns argo 2>/dev/null || echo "Namespace argo already exists"
helm upgrade --install argocd argo-cd -f argo-cd/values.custom.yaml -n argo

echo "Installing/Upgrading RabbitMQ"
helm upgrade --install rabbitmq rabbitmq -f rabbitmq/values.custom.yaml

# Dọn dẹp
cd /tmp || exit 1
rm -rf "${WORK_DIR}"

echo "Post-installation completed successfully"
#!/bin/sh
# Đảm bảo script tương thích với cả sh và bash

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

# Kiểm tra môi trường - sử dụng cú pháp tương thích với sh
if [ -n "$OSTYPE" ] && ([ "$OSTYPE" = "msys" ] || [ "$OSTYPE" = "cygwin" ]); then
  # Đang chạy trên Windows Git Bash
  WORK_DIR=$(mktemp -d -p /c/temp eks-post-install.XXXXXX 2>/dev/null || mktemp -d -p /tmp eks-post-install.XXXXXX)
else
  # Đang chạy trên Linux hoặc container
  WORK_DIR=$(mktemp -d)
fi

echo "Working directory: ${WORK_DIR}"
cd "${WORK_DIR}" || exit 1

# Clone repository
echo "Cloning k8s-repo repository"
git clone https://github.com/MeetingTeam/k8s-repo.git --branch main
cd k8s-repo/opensource || exit 1

# Chỉ cấu hình EFS và Jenkins trong môi trường dev
if [ "${ENV}" = "dev" ]; then
  # Gán cứng EFS ID
  export EFS_ID="fs-01c6b682f204b8176"

  if [ -n "$EFS_ID" ]; then
    echo "Configuring EFS PersistentVolume with ID: ${EFS_ID}"
    
    # Tạo PersistentVolume sử dụng EFS
    cat <<EOF > ${WORK_DIR}/jenkins-cache-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: jenkins-cache-pv
spec:
  capacity:
    storage: 6Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: ${EFS_ID}
    readOnly: false
EOF

    kubectl apply -f ${WORK_DIR}/jenkins-cache-pv.yaml
    echo "EFS PersistentVolume created successfully"
  else
    echo "EFS ID not found, skipping PersistentVolume creation"
  fi
fi

echo "Installing/Upgrading ArgoCD"
kubectl create ns argo 2>/dev/null || echo "Namespace argo already exists"
helm upgrade --install argocd argo-cd -f argo-cd/values.custom.yaml -n argo

# Chuyển sang thư mục argocd-apps để cài đặt applications
echo "Installing ArgoCD Applications"
cd ../argocd-apps || exit 1

# Cài đặt ArgoCD apps dựa trên môi trường
if [ "${ENV}" = "dev" ]; then
  echo "Installing ArgoCD apps for DEV environment"
  if [ -f "values.dev.yaml" ]; then
    helm upgrade --install argocd-apps . -f values.dev.yaml -n argo
    echo "ArgoCD apps installed with values.dev.yaml"
  else
    echo "values.dev.yaml not found, skipping ArgoCD apps installation"
  fi
elif [ "${ENV}" = "prod" ]; then
  echo "Installing ArgoCD apps for PROD environment"
  if [ -f "values.prod.yaml" ]; then
    helm upgrade --install argocd-apps . -f values.prod.yaml -n argo
    echo "ArgoCD apps installed with values.prod.yaml"
  else
    echo "values.prod.yaml not found, skipping ArgoCD apps installation"
  fi
else
  echo "Unknown environment: ${ENV}. Skipping ArgoCD apps installation"
fi

# Dọn dẹp
cd /tmp || exit 1
rm -rf "${WORK_DIR}"

echo "Post-installation completed successfully"
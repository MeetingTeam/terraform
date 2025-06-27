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

# Tạo working directory riêng cho từng environment
BASE_TEMP_NAME="eks-post-install-${ENV}"

# Kiểm tra môi trường - sử dụng cú pháp tương thích với sh
if [ -n "$OSTYPE" ] && ([ "$OSTYPE" = "msys" ] || [ "$OSTYPE" = "cygwin" ]); then
  # Đang chạy trên Windows Git Bash
  if [ "${ENV}" = "dev" ]; then
    WORK_DIR=$(mktemp -d -p /c/temp ${BASE_TEMP_NAME}-dev.XXXXXX 2>/dev/null || mktemp -d -p /tmp ${BASE_TEMP_NAME}-dev.XXXXXX)
  elif [ "${ENV}" = "prod" ]; then
    WORK_DIR=$(mktemp -d -p /c/temp ${BASE_TEMP_NAME}-prod.XXXXXX 2>/dev/null || mktemp -d -p /tmp ${BASE_TEMP_NAME}-prod.XXXXXX)
  else
    WORK_DIR=$(mktemp -d -p /c/temp ${BASE_TEMP_NAME}-${ENV}.XXXXXX 2>/dev/null || mktemp -d -p /tmp ${BASE_TEMP_NAME}-${ENV}.XXXXXX)
  fi
else
  # Đang chạy trên Linux hoặc container
  if [ "${ENV}" = "dev" ]; then
    WORK_DIR=$(mktemp -d -t ${BASE_TEMP_NAME}-dev.XXXXXX)
  elif [ "${ENV}" = "prod" ]; then
    WORK_DIR=$(mktemp -d -t ${BASE_TEMP_NAME}-prod.XXXXXX)
  else
    WORK_DIR=$(mktemp -d -t ${BASE_TEMP_NAME}-${ENV}.XXXXXX)
  fi
fi

echo "Working directory for ${ENV} environment: ${WORK_DIR}"
cd "${WORK_DIR}" || exit 1

# Clone repository
echo "Cloning k8s-repo repository for ${ENV} environment"
git clone https://github.com/MeetingTeam/k8s-repo.git --branch main
cd k8s-repo/opensource || exit 1

# Cấu hình EFS riêng cho từng môi trường
if [ "${ENV}" = "dev" ]; then
  echo "=== DEV Environment Configuration ==="
  # Gán cứng EFS ID cho dev (sẽ được thay thế bằng dynamic value)
  export EFS_ID="fs-01c6b682f204b8176"

  if [ -n "$EFS_ID" ]; then
    echo "Configuring EFS PersistentVolume for DEV with ID: ${EFS_ID}"
    
    # Tạo PersistentVolume sử dụng EFS cho dev
    cat <<EOF > ${WORK_DIR}/jenkins-cache-pv-dev.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: jenkins-cache-pv-dev
  labels:
    environment: dev
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

    kubectl apply -f ${WORK_DIR}/jenkins-cache-pv-dev.yaml
    echo "EFS PersistentVolume for DEV created successfully"
  else
    echo "EFS ID not found for DEV, skipping PersistentVolume creation"
  fi

elif [ "${ENV}" = "prod" ]; then
  echo "=== PROD Environment Configuration ==="
  # Prod có thể có EFS khác hoặc không cần EFS
  echo "PROD environment - EFS configuration skipped (if not needed)"
  # Uncomment nếu prod cần EFS:
  # export EFS_ID="fs-prod-xxxxxx"
  # if [ -n "$EFS_ID" ]; then
  #   echo "Configuring EFS PersistentVolume for PROD with ID: ${EFS_ID}"
  #   cat <<EOF > ${WORK_DIR}/jenkins-cache-pv-prod.yaml
  # apiVersion: v1
  # kind: PersistentVolume
  # metadata:
  #   name: jenkins-cache-pv-prod
  #   labels:
  #     environment: prod
  # spec:
  #   capacity:
  #     storage: 10Gi
  #   volumeMode: Filesystem
  #   accessModes:
  #     - ReadWriteMany
  #   persistentVolumeReclaimPolicy: Retain
  #   storageClassName: efs-sc
  #   csi:
  #     driver: efs.csi.aws.com
  #     volumeHandle: ${EFS_ID}
  #     readOnly: false
  # EOF
  #   kubectl apply -f ${WORK_DIR}/jenkins-cache-pv-prod.yaml
  #   echo "EFS PersistentVolume for PROD created successfully"
  # fi
fi

echo "Installing/Upgrading ArgoCD for ${ENV} environment"
kubectl create ns argo 2>/dev/null || echo "Namespace argo already exists"
helm upgrade --install argocd argo-cd -f argo-cd/values.custom.yaml -n argo

# Chuyển sang thư mục argocd-apps để cài đặt applications
echo "Installing ArgoCD Applications for ${ENV} environment"
cd ../argocd-apps || exit 1

# Cài đặt ArgoCD apps dựa trên môi trường với tên riêng biệt
if [ "${ENV}" = "dev" ]; then
  echo "=== Installing ArgoCD apps for DEV environment ==="
  if [ -f "values.dev.yaml" ]; then
    helm upgrade --install argocd-apps-dev . -f values.dev.yaml -n argo
    echo "ArgoCD apps for DEV installed with values.dev.yaml"
  else
    echo "values.dev.yaml not found, skipping ArgoCD apps installation for DEV"
  fi
elif [ "${ENV}" = "prod" ]; then
  echo "=== Installing ArgoCD apps for PROD environment ==="
  if [ -f "values.prod.yaml" ]; then
    helm upgrade --install argocd-apps-prod . -f values.prod.yaml -n argo
    echo "ArgoCD apps for PROD installed with values.prod.yaml"
  else
    echo "values.prod.yaml not found, skipping ArgoCD apps installation for PROD"
  fi
else
  echo "Unknown environment: ${ENV}. Skipping ArgoCD apps installation"
fi

# Hiển thị thông tin cuối cho environment
echo "=== Final status for ${ENV} environment ==="
echo "Working directory was: ${WORK_DIR}"
echo "ArgoCD namespace status:"
kubectl get ns argo 2>/dev/null || echo "argo namespace not found"
echo "ArgoCD pods:"
kubectl get pods -n argo 2>/dev/null || echo "No pods found in argo namespace"

# Dọn dẹp working directory
echo "Cleaning up working directory: ${WORK_DIR}"
cd /tmp || exit 1
rm -rf "${WORK_DIR}"

echo "Post-installation completed successfully for ${ENV} environment"
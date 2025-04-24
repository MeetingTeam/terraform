region            = "ap-southeast-1"
env               = "dev"
cluster_name      = "doan-cluster"
vpc_cidr          = "10.0.0.0/16"
kubernetes_version = "1.28"
key_name          = "volunteer-work-keypair"  # Thay bằng tên key pair thực tế nếu cần SSH access

# Các giá trị khác sẽ sử dụng default từ module
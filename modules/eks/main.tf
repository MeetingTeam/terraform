
##########################################
# EKS Cluster
##########################################
resource "aws_eks_cluster" "main" {
  name     = "${var.cluster_name}-${var.env}"
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    security_group_ids      = [var.cluster_sg_id]
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Enable EKS add-ons
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = merge(
    {
      Name        = "${var.cluster_name}-${var.env}"
      Environment = var.env
    },
    var.tags
  )

#   depends_on = [
#     # Đảm bảo cluster role đã được tạo trước
#     aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
#     aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController
#   ]
}

##########################################
# EKS Node Group - Standard Nodes
##########################################
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group-${var.env}"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  ami_type       = "AL2_x86_64" # Amazon Linux 2
  instance_types = var.instance_types
  capacity_type  = "ON_DEMAND"
  disk_size      = var.disk_size

  scaling_config {
    desired_size = var.desired_capacity
    min_size     = var.min_capacity
    max_size     = var.max_capacity
  }

  update_config {
    max_unavailable = 1
  }

  # Apply remote_access if key_name is specified
  dynamic "remote_access" {
    for_each = var.key_name != "" ? [1] : []
    content {
      ec2_ssh_key = var.key_name
      source_security_group_ids = [var.node_sg_id]
    }
  }

  labels = {
    role = "standard"
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-node-group-${var.env}"
      Environment = var.env
    },
    var.tags
  )

  # Allow EKS to manage IAM role and instance profile for worker nodes
#   depends_on = [
#     aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
#     aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
#   ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

##########################################
# EKS Add-ons
##########################################

# Addon: VPC CNI
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(
    {
      Name        = "${var.cluster_name}-vpc-cni-addon-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

# Addon: CoreDNS
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(
    {
      Name        = "${var.cluster_name}-coredns-addon-${var.env}"
      Environment = var.env
    },
    var.tags
  )

  # CoreDNS requires working nodes
  depends_on = [aws_eks_node_group.main]
}

# Addon: kube-proxy
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(
    {
      Name        = "${var.cluster_name}-kube-proxy-addon-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}
# Addon: EBS CSI Driver
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(
    {
      Name        = "${var.cluster_name}-ebs-csi-driver-addon-${var.env}"
      Environment = var.env
    },
    var.tags
  )

  # EBS CSI Driver requires working nodes and IAM permissions
  depends_on = [aws_eks_node_group.main]
}
resource "aws_eks_addon" "efs_csi_driver" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-efs-csi-driver"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(
    {
      Name        = "${var.cluster_name}-efs-csi-driver-addon-${var.env}"
      Environment = var.env
    },
    var.tags
  )

  # EFS CSI Driver requires working nodes and IAM permissions
  depends_on = [aws_eks_node_group.main]
}

# Addon: CloudWatch Observability
# resource "aws_eks_addon" "cloudwatch_observability" {
#   cluster_name = aws_eks_cluster.main.name
#   addon_name   = "amazon-cloudwatch-observability"

#   resolve_conflicts_on_create = "OVERWRITE"
#   resolve_conflicts_on_update = "PRESERVE"

#   tags = merge(
#     {
#       Name        = "${var.cluster_name}-cloudwatch-observability-addon-${var.env}"
#       Environment = var.env
#     },
#     var.tags
#   )

#   # Depends on node group and necessary IAM permissions being attached
#   depends_on = [
#     aws_eks_node_group.main 
#   ]
# }

##########################################
# Outputs để có thể kết nối đến cluster
##########################################
data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}
locals {
  is_container = fileexists("/proc/1/cgroup") ? (
    can(regex("docker", file("/proc/1/cgroup"))) || can(regex("kubepods", file("/proc/1/cgroup")))
  ) : false

  interpreter = local.is_container ? ["/bin/sh", "-c"] : ["C:/Program Files/Git/bin/bash.exe", "-c"]
}


resource "null_resource" "post_install" {
  # Chỉ chạy khi không phải trong container VÀ run_post_install_script = true
  count = (!local.is_container && var.run_post_install_script) ? 1 : 0

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.main,
    aws_eks_addon.coredns,
    aws_eks_addon.vpc_cni,
    aws_eks_addon.kube_proxy,
    aws_eks_addon.ebs_csi_driver,
    aws_eks_addon.efs_csi_driver
  ]

  # Trigger system
  triggers = {
    cluster_version = aws_eks_cluster.main.version
    run_time = var.force_update_post_install ? timestamp() : "initial-run"
  }

  provisioner "local-exec" {
    interpreter = ["C:/Program Files/Git/bin/bash.exe", "-c"]
    command     = "${path.module}/../../scripts/post_eks_install.sh ${var.cluster_name} ${var.region} ${var.env}"
  }
}
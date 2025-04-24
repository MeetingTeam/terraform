##########################################
# EKS Cluster Security Group 
##########################################
resource "aws_security_group" "eks_cluster_sg" {
  name        = "${var.cluster_name}-cluster-sg-${var.env}"
  description = "Security group for EKS cluster control plane"
  vpc_id      = var.vpc_id

  # Egress rules (không phụ thuộc)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-cluster-sg-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

##########################################
# EKS Node Group Security Group
##########################################
resource "aws_security_group" "eks_nodes_sg" {
  name        = "${var.cluster_name}-nodes-sg-${var.env}"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  # Egress rules (không phụ thuộc)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-nodes-sg-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

# Bổ sung các quy tắc security group sau khi cả hai SG đã được tạo
resource "aws_security_group_rule" "cluster_ingress_from_nodes" {
  security_group_id        = aws_security_group.eks_cluster_sg.id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  description              = "Allow pods to communicate with the cluster API Server"
}

resource "aws_security_group_rule" "cluster_ingress_https" {
  security_group_id = aws_security_group.eks_cluster_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow local network to communicate with the cluster API Server"
}

resource "aws_security_group_rule" "nodes_ingress_self" {
  security_group_id = aws_security_group.eks_nodes_sg.id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  description       = "Allow nodes to communicate with each other"
}

resource "aws_security_group_rule" "nodes_ingress_cluster" {
  security_group_id        = aws_security_group.eks_nodes_sg.id
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  description              = "Allow worker kubelets and pods to receive communication from the cluster control plane"
}

resource "aws_security_group_rule" "nodes_ingress_https" {
  security_group_id = aws_security_group.eks_nodes_sg.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane"
}

# Nếu có các quy tắc khác như SSH access, thêm ở dưới đây
resource "aws_security_group_rule" "nodes_ingress_ssh" {
  security_group_id = aws_security_group.eks_nodes_sg.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]  # Hoặc hạn chế hơn, ví dụ: [var.vpc_cidr]
  description       = "SSH access to worker nodes"
}
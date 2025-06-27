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

resource "aws_security_group_rule" "nodes_ingress_http" {
  security_group_id = aws_security_group.eks_nodes_sg.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP traffic from internet via load balancer"
}

# Allow load balancer health checks and traffic (optional if you create a separate LB security group)
resource "aws_security_group_rule" "nodes_ingress_health_checks" {
  security_group_id = aws_security_group.eks_nodes_sg.id
  type              = "ingress"
  from_port         = 31380
  to_port           = 31400
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]  # Ideally restrict to load balancer CIDR
  description       = "Allow traffic from load balancer to node ports"
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


# Security Group cho RDS MySQL
resource "aws_security_group" "rds_sg" {
  name        = "${var.cluster_name}-rds-sg-${var.env}"
  description = "Security group for RDS MySQL instances"
  vpc_id      = var.vpc_id

  # MySQL
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes_sg.id]
    description     = "Allow MySQL access from EKS nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-rds-sg-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

# Security Group cho DocumentDB
resource "aws_security_group" "docdb_sg" {
  name        = "${var.cluster_name}-docdb-sg-${var.env}"
  description = "Security group for DocumentDB cluster"
  vpc_id      = var.vpc_id

  # DocumentDB
  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes_sg.id]
    description     = "Allow DocumentDB access from EKS nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-docdb-sg-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

##########################################
resource "aws_security_group" "efs_sg" {
  name        = "${var.cluster_name}-efs-sg-${var.env}"
  description = "Security group for EFS mount targets"
  vpc_id      = var.vpc_id

  # Cho phép NFS traffic từ any source
  ingress {
    description = "NFS traffic from any source"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-efs-sg-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

resource "aws_security_group_rule" "nodes_ingress_nodeports" {
  security_group_id = aws_security_group.eks_nodes_sg.id
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow traffic to Kubernetes node ports"
}

# Cần thêm security group riêng cho Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "${var.cluster_name}-alb-sg-${var.env}"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
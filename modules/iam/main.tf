
resource "random_id" "suffix" {
  byte_length = 4
}
##########################################
# IAM Role for EKS Cluster
##########################################
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role-${var.env}-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(
    {
      Name        = "${var.cluster_name}-eks-cluster-role-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

# Attach required policies to the EKS cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

# Attaching EKS Service Policy to EKS Cluster role
resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

##########################################
# IAM Role for EKS Node Group
##########################################
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-eks-node-role-${var.env}-${random_id.suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(
    {
      Name        = "${var.cluster_name}-eks-node-role-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

# Attach required policies to the EKS node role
resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

# SSM access (để có thể truy cập vào node dễ dàng)
resource "aws_iam_role_policy_attachment" "eks_node_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_node_role.name
}

# Chỉ lấy thông tin account ID để sử dụng trong tags hoặc naming
data "aws_caller_identity" "current" {}


##########################################
# IAM Policy for Cluster Autoscaler
##########################################
resource "aws_iam_policy" "autoscaler" {
  name = "${var.cluster_name}-eks-autoscaler-policy-${var.env}-${random_id.suffix.hex}"
  description = "Policy for Kubernetes Cluster Autoscaler"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeTags",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeLaunchTemplateVersions"
        ],
        "Effect" : "Allow",
        "Resource" : "*"
      }
    ]
  })

  tags = merge(
    {
      Name        = "${var.cluster_name}-eks-autoscaler-policy-${var.env}-${random_id.suffix.hex}"
      Environment = var.env
    },
    var.tags
  )
}

# # Attaching X-Ray Policy to EKS Node role
# resource "aws_iam_role_policy_attachment" "eks_node_XRayDaemonWriteAccess" {
#   policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
#   role       = aws_iam_role.eks_node_role.name
# }

# Attaching S3 Read Policy to EKS Node role
resource "aws_iam_role_policy_attachment" "eks_node_S3ReadOnlyAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.eks_node_role.name
}

# Attaching Autoscaler Policy to EKS Node role
resource "aws_iam_role_policy_attachment" "eks_node_autoscaler" {
  policy_arn = aws_iam_policy.autoscaler.arn
  role       = aws_iam_role.eks_node_role.name
}

# Creating Instance Profile for EKS Node role
resource "aws_iam_instance_profile" "eks_node_profile" {
  name = "${var.cluster_name}-eks-node-profile-${var.env}-${random_id.suffix.hex}"
  role = aws_iam_role.eks_node_role.name
}
# Attaching EBS CSI Driver Policy to EKS Node role
resource "aws_iam_role_policy_attachment" "eks_node_AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_node_role.name
}


# Attaching EFS CSI Driver Policy to EKS Node role
resource "aws_iam_role_policy_attachment" "eks_node_AmazonEFSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.eks_node_role.name
}

# 1. Get the policy document for CloudWatchAgentServerPolicy
data "aws_iam_policy" "cloudwatch_agent" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# 2. Create a combined policy
resource "aws_iam_policy" "combined_monitoring_lb" {
  name        = "${var.cluster_name}-combined-monitoring-lb-${var.env}"
  description = "Combined policy for CloudWatch and Load Balancer Controller"
  
  # Merge both policy statements
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat(
      jsondecode(data.aws_iam_policy.cloudwatch_agent.policy).Statement,
      [
        {
          Effect = "Allow",
          Action = [
            "ec2:CreateTags",
            "ec2:DeleteTags",
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeAddresses",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeSubnets",
            "ec2:DescribeTags",
            "ec2:DescribeVpcs",
            "elasticloadbalancing:*",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:CreateSecurityGroup",
            "ec2:ModifyInstanceAttribute",
            "ec2:RevokeSecurityGroupIngress"
          ],
          Resource = "*"
        }
      ]
    )
  })
}

# 3. Remove the individual policy attachments
# DELETE: aws_iam_role_policy_attachment.eks_node_CloudWatchAgentServerPolicy
# DELETE: aws_iam_role_policy_attachment.eks_node_LoadBalancerControllerPolicy

# 4. Add combined policy attachment
resource "aws_iam_role_policy_attachment" "eks_node_combined_monitoring_lb" {
  policy_arn = aws_iam_policy.combined_monitoring_lb.arn
  role       = aws_iam_role.eks_node_role.name
}
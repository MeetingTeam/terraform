resource "aws_efs_file_system" "jenkins_cache" {
  creation_token = "${var.cluster_name}-jenkins-cache-${var.env}"
  encrypted      = true
  
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = merge(
    {
      Name        = "${var.cluster_name}-jenkins-cache-${var.env}"
      Environment = var.env
    },
    var.tags
  )
}

resource "aws_efs_mount_target" "jenkins_cache" {
  count = length(var.private_subnet_ids)
  
  file_system_id  = aws_efs_file_system.jenkins_cache.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [var.security_group_id]
}
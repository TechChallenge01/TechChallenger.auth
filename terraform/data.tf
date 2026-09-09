
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Name"
    values = [var.private_subnet_name_pattern]
  }
}

data "aws_security_group" "rds" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "tag:Name"
    values = [var.rds_sg_name]
  }
}

data "aws_eks_cluster" "app" {
  name = var.eks_cluster_name
}

data "aws_autoscaling_groups" "eks_nodes" {
  filter {
    name   = "tag:eks:cluster-name"
    values = [var.eks_cluster_name]
  }
}

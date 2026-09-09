resource "aws_lb" "internal" {
  name                             = "${var.name_prefix}-nlb"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = data.aws_subnets.private.ids
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.name_prefix}-nlb"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.name_prefix}-app-tg"
  port        = var.app_node_port
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.main.id
  target_type = "instance"

  health_check {
    protocol            = "TCP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 15
  }

  tags = {
    Name = "${var.name_prefix}-app-tg"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_autoscaling_attachment" "eks_nodes" {
  count                  = length(data.aws_autoscaling_groups.eks_nodes.names)
  autoscaling_group_name = tolist(data.aws_autoscaling_groups.eks_nodes.names)[count.index]
  lb_target_group_arn    = aws_lb_target_group.app.arn
}

resource "aws_security_group_rule" "nodeport_from_vpc" {
  type              = "ingress"
  description       = "NodePort da TechChallenge API via NLB interno / API Gateway VPC Link"
  from_port         = var.app_node_port
  to_port           = var.app_node_port
  protocol          = "tcp"
  security_group_id = data.aws_eks_cluster.app.vpc_config[0].cluster_security_group_id
  cidr_blocks       = [data.aws_vpc.main.cidr_block]
}

resource "aws_autoscaling_group" "asg" {
  health_check_grace_period = 5
  max_instance_lifetime     = var.instance_lifetime
  default_cooldown          = 900
  health_check_type         = "EC2"
  max_size                  = var.max_size
  min_size                  = var.min_size
  name                      = var.group
  placement_group           = aws_placement_group.pg.name
  vpc_zone_identifier       = var.private_subnets
  termination_policies      = ["Default"]
  force_delete              = false
  target_group_arns         = [aws_lb_target_group.tg.arn]
  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances"
  ]
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }
  initial_lifecycle_hook {
    name                 = "LAUNCHING"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 60
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  }

  initial_lifecycle_hook {
    name                 = "TERMINATING"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 600
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
  }

  tag {
    key                 = "Name"
    value               = var.group
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = toset(var.salt_roles)
    content {
      key                 = "Role"
      value               = tag.value
      propagate_at_launch = true
    }
  }

}

resource "aws_autoscaling_policy" "asg_policy" {
  name                      = var.group
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 120
  autoscaling_group_name    = aws_autoscaling_group.asg.name
  adjustment_type           = "ChangeInCapacity"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_value
  }
}





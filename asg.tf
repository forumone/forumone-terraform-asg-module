resource "aws_autoscaling_group" "asg" {
  health_check_grace_period = 5
  max_instance_lifetime     = var.instance_lifetime
  default_cooldown          = var.cooldown
  health_check_type         = "EC2"
  max_size                  = var.max_size
  min_size                  = var.min_size
  name                      = var.group_name
  placement_group           = aws_placement_group.pg.name
  vpc_zone_identifier       = var.private_subnets
  termination_policies      = ["Default"]
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

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }

  # This will enable automatic instance refresh if the automate_instance_refresh variable
  # is set to to true which will update instances when the launch template is changed
  # defaults to false
  dynamic "instance_refresh" {
    for_each = var.automate_instance_refresh != false ? [1] : []
    content {
      strategy = "Rolling"
      preferences {
        checkpoint_delay       = 600
        checkpoint_percentages = [35, 70, 100]
        instance_warmup        = 300
        min_healthy_percentage = 50
        auto_rollback          = true
      }
    }
  }

  tag {
    key                 = "Name"
    value               = var.group_name
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = toset(var.salt_roles)
    content {
      key                 = tag.value
      value               = "salt_role"
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_policy" "asg_policy" {
  name                      = var.group_name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = var.warmup
  autoscaling_group_name    = aws_autoscaling_group.asg.name
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_value
  }
}




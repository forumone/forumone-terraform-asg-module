output "tg_arn_suffix" {
  value       = aws_lb_target_group.tg.arn_suffix
  description = "The Target Groups ARN Suffix"
}

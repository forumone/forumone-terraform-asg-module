# AWS Auto Scaling Group (ASG) Terraform module - For use with Salt Stack
  - This module sets the defaults for ASG to connect to a salt-stack configuration management host.
  - The module will use the data from the salt-stack pillar files or properly formatted yaml files to create resources.
  - This will create an: ASG, Launch Templates, target groups and ALB Routes for each URL
  - It will also conditionally create Route 53 Records and SSL Certificates with ACM
  - see examples folder for yaml structure and module inputs

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.6 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.27 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.27 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_sites_acm"></a> [sites\_acm](#module\_sites\_acm) | terraform-aws-modules/acm/aws | ~> 4.3 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_attachment.attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_attachment) | resource |
| [aws_autoscaling_group.asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_policy.asg_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_launch_template.lt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_lb_listener_certificate.acm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate) | resource |
| [aws_lb_listener_rule.lb_routes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.tg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_placement_group.pg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/placement_group) | resource |
| [aws_route53_record.host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_lb.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb) | data source |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb_listener) | data source |
| [aws_route53_zone.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_name"></a> [alb\_name](#input\_alb\_name) | n/a | `any` | n/a | yes |
| <a name="input_ami"></a> [ami](#input\_ami) | n/a | `any` | n/a | yes |
| <a name="input_client"></a> [client](#input\_client) | n/a | `any` | n/a | yes |
| <a name="input_ec2_iam_profile"></a> [ec2\_iam\_profile](#input\_ec2\_iam\_profile) | n/a | `any` | n/a | yes |
| <a name="input_environments"></a> [environments](#input\_environments) | n/a | `list(string)` | n/a | yes |
| <a name="input_group_name"></a> [group\_name](#input\_group\_name) | n/a | `any` | n/a | yes |
| <a name="input_ofs_bucket"></a> [ofs\_bucket](#input\_ofs\_bucket) | n/a | `any` | n/a | yes |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | n/a | `list(string)` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | n/a | `any` | n/a | yes |
| <a name="input_salt_roles"></a> [salt\_roles](#input\_salt\_roles) | n/a | `list(string)` | n/a | yes |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | n/a | `list(string)` | n/a | yes |
| <a name="input_suffix"></a> [suffix](#input\_suffix) | n/a | `any` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `any` | n/a | yes |
| <a name="input_yaml_files"></a> [yaml\_files](#input\_yaml\_files) | n/a | `list(string)` | n/a | yes |
| <a name="input_automate_instance_refresh"></a> [automate\_instance\_refresh](#input\_automate\_instance\_refresh) | n/a | `bool` | `false` | no |
| <a name="input_cooldown"></a> [cooldown](#input\_cooldown) | n/a | `string` | `"900"` | no |
| <a name="input_cpu_value"></a> [cpu\_value](#input\_cpu\_value) | n/a | `string` | `"60"` | no |
| <a name="input_create_route53_records"></a> [create\_route53\_records](#input\_create\_route53\_records) | n/a | `bool` | `true` | no |
| <a name="input_create_ssl_certificates"></a> [create\_ssl\_certificates](#input\_create\_ssl\_certificates) | n/a | `bool` | `true` | no |
| <a name="input_ebs_volume_size"></a> [ebs\_volume\_size](#input\_ebs\_volume\_size) | n/a | `string` | `"150"` | no |
| <a name="input_instance_lifetime"></a> [instance\_lifetime](#input\_instance\_lifetime) | n/a | `string` | `"1209600"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | n/a | `string` | `"t3a.medium"` | no |
| <a name="input_launch_template_file"></a> [launch\_template\_file](#input\_launch\_template\_file) | n/a | `string` | `""` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | n/a | `string` | `"10"` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | n/a | `string` | `"1"` | no |
| <a name="input_ofs_cache_size"></a> [ofs\_cache\_size](#input\_ofs\_cache\_size) | n/a | `string` | `"100G"` | no |
| <a name="input_ofs_license"></a> [ofs\_license](#input\_ofs\_license) | n/a | `string` | `""` | no |
| <a name="input_ofs_passphrase"></a> [ofs\_passphrase](#input\_ofs\_passphrase) | n/a | `string` | `""` | no |
| <a name="input_salt_master"></a> [salt\_master](#input\_salt\_master) | n/a | `string` | `"salt"` | no |
| <a name="input_sendgrid_api_key"></a> [sendgrid\_api\_key](#input\_sendgrid\_api\_key) | n/a | `string` | `""` | no |
| <a name="input_warmup"></a> [warmup](#input\_warmup) | n/a | `string` | `"120"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_tg_arn_suffix"></a> [tg\_arn\_suffix](#output\_tg\_arn\_suffix) | The Target Groups ARN Suffix |
<!-- END_TF_DOCS -->
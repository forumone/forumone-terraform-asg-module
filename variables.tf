variable "alb_name" {}
variable "max_size" { default = "10" }
variable "min_size" { default = "1" }
variable "project" {}
variable "client" {}
variable "environments" {
  type = list(string)
}
variable "private_subnets" {
  type = list(string)
}
variable "salt_roles" {
  type = list(string)
}
variable "cpu_value" { default = "60" }
variable "ami" {}
variable "instance_type" { default = "t3a.medium" }
variable "security_groups" {
  type = list(string)
}
variable "ec2_iam_profile" {}
variable "ebs_volume_size" { default = "150" }
variable "ofs_license" { default = "" }
variable "ofs_passphrase" { default = "" }
variable "ofs_cache_size" { default = "100G" }
variable "vpc_id" {}
variable "suffix" {}
variable "group_name" {}
variable "sendgrid_api_key" { default = "" }
variable "yaml_files" {
  type = list(string)
}
variable "ofs_bucket" {}
variable "salt_master" { default = "salt" }
variable "instance_lifetime" { default = "1209600" }
variable "create_ssl_certificates" {
  type    = bool
  default = true
}
variable "create_route53_records" {
  type    = bool
  default = true
}
variable "launch_template_file" { default = "" }
variable "automate_instance_refresh" {
  type    = bool
  default = false
}
variable "warmup" { default = "120" }
variable "cooldown" { default = "900" }


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
variable "salt_role" {}
variable "cpu_value" { default = "60" }
variable "ami" {}
variable "instance_type" { default = "t3a.medium" }
variable "security_groups" {
  type = list(string)
}
variable "ec2_iam_profile" {}
variable "ebs_volume_size" { default = "150" }
variable "ofs_license" {}
variable "ofs_passphrase" {}
variable "vpc_id" {}
variable "suffix" {}
variable "group" {}
variable "sendgrid_api_key" {}
variable "pillar_file" {}
variable "ofs_bucket" {}

module "group_1" {
  source           = "../../"
  alb_name         = ""
  ami              = ""
  client           = ""
  cpu_value        = "60"
  ebs_volume_size  = "150"
  ec2_iam_profile  = ""
  environments     = ""
  group            = ""
  instance_type    = "t3a.medium"
  max_size         = "10"
  min_size         = "1"
  ofs_bucket       = ""
  ofs_license      = ""
  ofs_passphrase   = ""
  yaml_file        = ""
  private_subnets  = ""
  project          = ""
  salt_master      = "salt"
  salt_role        = ""
  security_groups  = ""
  sendgrid_api_key = ""
  suffix           = ""
  vpc_id           = ""
}

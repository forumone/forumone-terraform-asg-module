resource "aws_launch_template" "lt" {
  name_prefix            = "${var.group_name}-"
  image_id               = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = var.security_groups
  user_data              = try(base64encode(file("${var.launch_template_file}")), base64encode(local.cloud_init))
  iam_instance_profile {
    name = var.ec2_iam_profile
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.ebs_volume_size
      volume_type = "gp3"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  lifecycle {
    create_before_destroy = true
  }

}

# default launch template for salt backed ASG's
# including OFS password and key and sendgrid API key
# since salt has troubles with param store

locals {
  cloud_init = <<EOF
    #cloud-config
    package_upgrade: true
    package_upgrade: true
    write_files:
    # Objective FS
      - path: "/etc/objectivefs.env/AWS_METADATA_HOST"
        content: "169.254.169.254"
        permissions: "0400"
        owner: "root"
      - path: "/etc/objectivefs.env/OBJECTIVEFS_LICENSE"
        content: "${var.ofs_license}"
        permissions: "0400"
        owner: "root"
      - path: "/etc/objectivefs.env/OBJECTIVEFS_PASSPHRASE"
        content: "${var.ofs_passphrase}"
        permissions: "0400"
        owner: "root"
      - path: "/etc/objectivefs.env/DISKCACHE_SIZE"
        content: "${var.ofs_cache_size}"
        permissions: "0400"
        owner: "root"
      - path: "/etc/objectivefs.env/DISKCACHE_PATH"
        content: "/var/cache/ofs"
        permissions: "0400"
        owner: "root"
    # Salt Minion
      - path: "/etc/salt/minion.d/master.conf"
        content: |
          master: ${var.salt_master}
      - path: "/etc/salt/minion.d/grains.conf"
        content: |
          grains:
            roles:
          %{~for role in var.salt_roles~}
              - ${role}
          %{~endfor~}
            env:
          %{~for env in var.environments~}
              - ${env}
          %{~endfor~}
            project:
              - ${var.project}
            suffix:
              - ${var.suffix}
            client:
              - ${var.client}
            group:
              - ${var.group_name}
          startup_states: highstate
          log_level: warning
          top_file_merging_strategy: same
        permissions: "0400"
        owner: "root"
    # Postfix Sendgrid Relay
      - path: "/etc/postfix/sasl_passwd"
        permissions: 0600
        owner: "root:root"
        content: |
          [smtp.sendgrid.net]:587 apikey:${var.sendgrid_api_key}
    runcmd:
      - echo "id:" $(/bin/jq -r .v1.instance_id /var/run/cloud-init/instance-data.json) >> /etc/salt/minion.d/id.conf
      - mkdir -p /var/cache/ofs
      - mkdir -p /var/www
      - |
        echo "s3://${var.ofs_bucket} /var/www objectivefs _netdev,acl,auto,mboost,mt,nonempty 0 0" >> /etc/fstab
      - mount -a
      - systemctl --now enable salt-minion.service
  EOF
}

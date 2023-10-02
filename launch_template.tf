resource "aws_launch_template" "lt" {
  name_prefix            = "${var.group}-${var.project}-"
  image_id               = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = var.security_groups
  user_data              = base64encode(local.cloud_init)
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
        content: "50G"
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
              - ${var.salt_role}
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
              - ${var.group}
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
      - path: "/etc/postfix/main.cf"
        permissions: 0644
        owner: "root:root"
        encoding: b64
        content: bXlob3N0bmFtZSA9IGxvY2FsaG9zdApteWRlc3RpbmF0aW9uID0gbG9jYWxob3N0CmluZXRfaW50ZXJmYWNlcyA9IGxvb3BiYWNrLW9ubHkKaW5ldF9wcm90b2NvbHMgPSBhbGwKc210cGRfdGxzX2NlcnRfZmlsZSA9IC9ldGMvc3NsL2NlcnRzL3NzbC1jZXJ0LXNuYWtlb2lsLnBlbQpzbXRwZF90bHNfa2V5X2ZpbGUgPSAvZXRjL3NzbC9wcml2YXRlL3NzbC1jZXJ0LXNuYWtlb2lsLmtleQpzbXRwZF90bHNfc2VjdXJpdHlfbGV2ZWwgPSBtYXkKc210cF90bHNfc2VjdXJpdHlfbGV2ZWwgPSBlbmNyeXB0CnNtdHBfdGxzX0NBcGF0aCA9IC9ldGMvc3NsL2NlcnRzCnNtdHBkX3Nhc2xfYXV0aF9lbmFibGUgPSB5ZXMKc210cGRfc2FzbF9zZWN1cml0eV9vcHRpb25zID0gbm9hbm9ueW1vdXMsIG5vcGxhaW50ZXh0CnNtdHBkX3Nhc2xfdGxzX3NlY3VyaXR5X29wdGlvbnMgPSBub2Fub255bW91cwpzbXRwZF90bHNfYXV0aF9vbmx5ID0geWVzCnJlbGF5aG9zdCA9IFtzbXRwLnNlbmRncmlkLm5ldF06NTg3CnNtdHBfc2FzbF9wYXNzd29yZF9tYXBzID0gaGFzaDovZXRjL3Bvc3RmaXgvc2FzbF9wYXNzd2QKc210cGRfcmVjaXBpZW50X3Jlc3RyaWN0aW9ucyA9IHBlcm1pdF9teW5ldHdvcmtzLCBwZXJtaXRfc2FzbF9hdXRoZW50aWNhdGVkLCByZWplY3RfdW5hdXRoX2Rlc3RpbmF0aW9uCnNtdHBkX3JlbGF5X3Jlc3RyaWN0aW9ucyA9IHBlcm1pdF9teW5ldHdvcmtzLCBwZXJtaXRfc2FzbF9hdXRoZW50aWNhdGVkLCBkZWZlcl91bmF1dGhfZGVzdGluYXRpb24KYWxpYXNfbWFwcyA9IGhhc2g6L2V0Yy9hbGlhc2VzCmFsaWFzX2RhdGFiYXNlID0gaGFzaDovZXRjL2FsaWFzZXMKbWVzc2FnZV9zaXplX2xpbWl0ID0gNDE5NDMwNDAKaGVhZGVyX3NpemVfbGltaXQgPSA0MDk2MDAwCmRpc2FibGVfdnJmeV9jb21tYW5kID0geWVzCg==
    runcmd:
      - echo "id:" $(/bin/jq -r .v1.instance_id /var/run/cloud-init/instance-data.json) >> /etc/salt/minion.d/id.conf
      - mkdir -p /var/cache/ofs
      - mkdir -p /var/www
      - postmap /etc/postfix/sasl_passwd
      - |
        echo "s3://${var.ofs_bucket}/www /var/www objectivefs _netdev,acl,auto,mboost,mt,nonempty 0 0" >> /etc/fstab
      - mount -a
      - systemctl --now enable postfix
      - systemctl --now enable salt-minion.service
  EOF
}

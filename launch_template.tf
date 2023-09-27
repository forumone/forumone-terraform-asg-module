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
    packages:
      - mailx
      - postfix
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
        content: bXlob3N0bmFtZSA9ICRteWhvc3RuYW1lCm15ZGVzdGluYXRpb24gPSBsb2NhbGhvc3QKaW5ldF9pbnRlcmZhY2VzID0gbG9vcGJhY2stb25seQppbmV0X3Byb3RvY29scyA9IGFsbApzbXRwZF90bHNfY2VydF9maWxlID0gL2V0Yy9zc2wvY2VydHMvc3NsLWNlcnQtc25ha2VvaWwucGVtCnNtdHBkX3Rsc19rZXlfZmlsZSA9IC9ldGMvc3NsL3ByaXZhdGUvc3NsLWNlcnQtc25ha2VvaWwua2V5CnNtdHBkX3Rsc19zZWN1cml0eV9sZXZlbCA9IG1heQpzbXRwX3Rsc19zZWN1cml0eV9sZXZlbCA9IGVuY3J5cHQKc210cF90bHNfQ0FwYXRoID0gL2V0Yy9zc2wvY2VydHMKc210cGRfc2FzbF9hdXRoX2VuYWJsZSA9IHllcwpzbXRwZF9zYXNsX3NlY3VyaXR5X29wdGlvbnMgPSBub2Fub255bW91cywgbm9wbGFpbnRleHQKc210cGRfc2FzbF90bHNfc2VjdXJpdHlfb3B0aW9ucyA9IG5vYW5vbnltb3VzCnNtdHBkX3Rsc19hdXRoX29ubHkgPSB5ZXMKcmVsYXlob3N0ID0gW3NtdHAuc2VuZGdyaWQubmV0XTo1ODcKc210cF9zYXNsX3Bhc3N3b3JkX21hcHMgPSBoYXNoOi9ldGMvcG9zdGZpeC9zYXNsX3Bhc3N3ZApzbXRwZF9yZWNpcGllbnRfcmVzdHJpY3Rpb25zID0gcGVybWl0X215bmV0d29ya3MsIHBlcm1pdF9zYXNsX2F1dGhlbnRpY2F0ZWQsIHJlamVjdF91bmF1dGhfZGVzdGluYXRpb24Kc210cGRfcmVsYXlfcmVzdHJpY3Rpb25zID0gcGVybWl0X215bmV0d29ya3MsIHBlcm1pdF9zYXNsX2F1dGhlbnRpY2F0ZWQsIGRlZmVyX3VuYXV0aF9kZXN0aW5hdGlvbgphbGlhc19tYXBzID0gaGFzaDovZXRjL2FsaWFzZXMKYWxpYXNfZGF0YWJhc2UgPSBoYXNoOi9ldGMvYWxpYXNlcwptZXNzYWdlX3NpemVfbGltaXQgPSA0MTk0MzA0MApoZWFkZXJfc2l6ZV9saW1pdCA9IDQwOTYwMDAKZGlzYWJsZV92cmZ5X2NvbW1hbmQgPSB5ZXMK
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

# This will read all the yaml files with the proper format (See examples foler)
# and convert hat information into a map for easy injestion by the module parts

locals {
  php_sites = flatten([
    for f in var.yaml_files : [
      for name, site in try(yamldecode(file(f)).vhosts.sites, []) : [
        for env, instance in site.instances : {
          name           = name
          env            = env
          url            = try(instance.urls, null)
          create_ssl     = try(instance.create_ssl, null)
          create_route53 = try(instance.create_route53, null)
        }
      ]
    ]
  ])
  node_sites = flatten([
    for f in var.yaml_files : [
      for name, site in try(yamldecode(file(f)).node.sites, []) : [
        for env, instance in site.instances : {
          name           = name
          env            = env
          url            = try(instance.urls, null)
          create_ssl     = try(instance.create_ssl, null)
          create_route53 = try(instance.create_route53, null)
        }
      ]
    ]
  ])

  mapped_sites = concat(local.node_sites, local.php_sites)
}

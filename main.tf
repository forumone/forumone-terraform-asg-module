# This will read all the yaml files with the proper format (See examples foler)
# and convert hat information into a map for easy injestion by the module parts

locals {
  mapped_sites = flatten([
    for f in var.yaml_files : [
      for type, host in yamldecode(file(f)) : [
        for name, site in try(host.sites, []) : [
          for env, instance in site.instances : {
            name           = name
            env            = env
            url            = try(instance.urls, null)
            create_ssl     = try(instance.create_ssl, null)
            create_route53 = try(instance.create_route53, null)
          }
        ]
      ]
    ]
  ])
}

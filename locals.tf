locals {
  # pull in pillar data from pillar file
  pillar_data = yamldecode(file("${var.yaml_file}"))
  php_hosts   = try(local.pillar_data.vhosts.sites, {})
  node_hosts  = try(local.pillar_data.node.sites, {})
  suffix      = "${var.project}.${var.suffix}"

  # make a data set of the php and node vhosts
  php_map = flatten([
    for name, site in local.php_hosts : [
      for env, instance in site.instances : {
        name = name
        env  = env
        url  = try(instance.urls, null)
      }
    ]
  ])

  node_map = flatten([
    for name, site in local.node_hosts : [
      for env, instance in site.instances : {
        name = name
        env  = env
        url  = try(instance.urls, null)
      }
    ]
  ])

  # make one set of site names
  # get sites from pillar 
  php_sites = distinct(flatten([
    for site, name in local.php_map : [
      name.name
    ]
  ]))

  node_sites = distinct(flatten([
    for site, name in local.node_map : [
      name.name
    ]
  ]))

  # combine the php and node pillar users to 1 set for okta to injest
  sites = concat(local.php_sites, local.node_sites)

  # get var.environments to create host headers
  env_urls = flatten([
    for site in local.sites : [
      for env in var.environments :
      "${env}.${site}.${var.suffix}"
      if env != "www"
    ]
  ])

  # get defined urls defined from pillar 
  php_defined_urls = distinct(flatten([
    for env in var.environments : [
      for site, name in local.php_map : [
        name.url
      ]
      if name.url != null && name.env == env
  ]]))

  node_defined_urls = distinct(flatten([
    for env in var.environments : [
      for site, name in local.node_map : [
        name.url
      ]
      if name.url != null && name.env == env
  ]]))

  # combine the 2 list above
  defined_urls = concat(local.php_defined_urls, local.node_defined_urls)

  # create a complete list of host headers for the ALB routes
  host_headers       = concat(local.defined_urls, local.env_urls)
  host_header_chunks = chunklist(local.host_headers, 5)

  # create a list of local hostheaders for Route53 and ACM
  all_env_urls = flatten([
    for site in local.sites : [
      for env in var.environments :
      "${env}.${site}.${var.suffix}"
    ]
  ])
}

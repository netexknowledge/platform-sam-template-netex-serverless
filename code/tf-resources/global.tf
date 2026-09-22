locals {
  tags       = (var.pipelinetags == null) ? merge(var.tags, var.temporaltags) : merge(merge(var.tags, var.temporaltags), var.pipelinetags)
  aws_region = (var.pipelineawsregion == null) ? var.aws_region : var.pipelineawsregion

  global_properties_file_path      = "${path.module}/../properties/global.yaml"
  environment_properties_file_path = "${path.module}/../properties/${local.tags.environment}.yaml"

  raw_properties_file_global = fileexists(local.global_properties_file_path) ? file(local.global_properties_file_path) : ""
  parsed_properties_global   = trimspace(local.raw_properties_file_global) != "" ? yamldecode(local.raw_properties_file_global) : {}
  properties_global = merge(
    { properties = { terrasam = true } },
    local.parsed_properties_global
  )

  raw_properties_file_env = fileexists(local.environment_properties_file_path) ? file(local.environment_properties_file_path) : ""
  parsed_properties_env   = trimspace(local.raw_properties_file_env) != "" ? yamldecode(local.raw_properties_file_env) : {}
  properties_env = merge(
    { properties = { terrasam = true } },
    local.parsed_properties_env
  )

  global_properties_map = try(local.properties_global.properties, {})
  env_properties_map    = try(local.properties_env.properties, {})

  global_keys = try(keys(local.global_properties_map), [])
  env_keys    = try(keys(local.env_properties_map), [])

  combined_keys = length(local.global_keys) > 0 ? distinct(concat(local.global_keys, local.env_keys)) : local.env_keys


  properties_raw = {
    for key in local.combined_keys : key => (
      local.env_properties_map != null ? lookup(local.env_properties_map, key, null) != null ? lookup(local.env_properties_map, key, null) : local.global_properties_map != null ? lookup(local.global_properties_map, key, null) : null : local.global_properties_map != null ? lookup(local.global_properties_map, key, null) : null
    )
  }

  properties = {
    for key, value in local.properties_raw : format("local.properties.%s", key) => value
  }

  custom_domain_name = (var.pipelinecustomdomainname == null) ? var.custom_domain_name : var.pipelinecustomdomainname

  vpc_security_group_ids = (var.pipelinevpcsecuritygroupids == null) ? var.vpc_security_group_ids : var.pipelinevpcsecuritygroupids
  vpc_subnet_ids         = (var.pipelinevpcsubnetids == null) ? var.vpc_subnet_ids : var.pipelinevpcsubnetids
}

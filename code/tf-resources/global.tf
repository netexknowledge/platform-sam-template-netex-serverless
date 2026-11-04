locals {
  tags       = (var.pipelinetags == null) ? merge(var.tags, var.temporaltags) : merge(merge(var.tags, var.temporaltags), var.pipelinetags)
  aws_region = (var.pipelineawsregion == null) ? var.aws_region : var.pipelineawsregion

  # Region de DR que anuncia la pipeline, si la hay. Vacio significa "no
  # replicar": es el estado de hoy y tiene que seguir siendo el que no cambia
  # nada. La pipeline no la anuncia cuando el propio despliegue va a la region
  # de DR, para que una tabla no intente replicarse sobre si misma.
  dr_regions = (var.pipelinedrregion == null || var.pipelinedrregion == "") ? [] : [var.pipelinedrregion]

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

  # Orden de preferencia: lo que diga la pipeline, luego lo que diga el tfvars
  # del repo, y como ultimo recurso lo que se descubra en AWS por convencion de
  # nombres. Ese ultimo escalon es el que hace posible desplegar en la region de
  # DR sin mantener a mano una lista de subnets de otra region: en eu-central-1
  # los identificadores ya cambiaron una vez entre octubre y noviembre de 2026.
  # No se usa coalesce: trata una lista vacia como valor valido y se quedaria
  # con ella, desactivando el descubrimiento sin avisar. Hoy ningun repo pone
  # estas variables -las dos vienen a null- pero el dia que alguien escriba
  # vpc_subnet_ids = [] no debe quedarse sin red en silencio.
  vpc_security_group_ids = (
    try(length(var.pipelinevpcsecuritygroupids), 0) > 0 ? var.pipelinevpcsecuritygroupids :
    try(length(var.vpc_security_group_ids), 0) > 0 ? var.vpc_security_group_ids :
    try(data.aws_security_groups.privado[0].ids, [])
  )
  vpc_subnet_ids = (
    try(length(var.pipelinevpcsubnetids), 0) > 0 ? var.pipelinevpcsubnetids :
    try(length(var.vpc_subnet_ids), 0) > 0 ? var.vpc_subnet_ids :
    try(data.aws_subnets.privadas[0].ids, [])
  )
}

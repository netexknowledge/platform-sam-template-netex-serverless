locals {
  connections = {
    for job, details in lookup(var.glue, "jobs", {}) :
    job => [for conn in lookup(details, "connections", []) : lookup(module.glue_connections, conn, null)]
  }

  connections_list_id = {
    for job, details in lookup(var.glue, "jobs", {}) :
    job => [for conn in lookup(details, "connections", []) :
      module.glue_connections[conn].glue_connection.name
    ]
  }

  connections_list_secretname = {
    for job, details in lookup(var.glue, "jobs", {}) :
    job => [
      for conn in lookup(details, "connections", []) :
      { "secret_name" : lookup(var.glue.connections[conn], "secret_name", null) }
      if lookup(var.glue.connections[conn], "secret_name", null) != null
    ]
  }

  connections_sg_ids = distinct(flatten([
    for connection, details in lookup(var.glue, "connections", {}) :
    can(tostring(details.security_group_id_list)) ? lookup(local.properties, details.security_group_id_list, []) : tolist(details.security_group_id_list)
  ]))

  job_triggers_list = {
    for job, details in lookup(var.glue, "jobs", {}) :
    job => [
      for name, trigger in lookup(details, "triggers", []) :
      {
        "name" : name,
        "job_name" = job,
        "config" : trigger
      }
      if lookup(var.glue.jobs[job], "triggers", null) != null
    ]
  }

  triggers_list = { for k, v in flatten([
    for job, triggers in local.job_triggers_list : [
      for trigger in triggers : {
        key   = "${job}-${trigger.name}"
        value = trigger
      }
    ]
  ]) : v.key => v.value }

  scripts_dir_path_list_jobs = {
    for job, details in lookup(var.glue, "jobs", {}) :
    job => {
      "script_dir_path" = lookup(var.glue.jobs[job], "script_file_path", "") != "" ? dirname(var.glue.jobs[job].script_file_path) : lookup(var.glue.jobs[job], "arguments_dir_path", "")
    }
  }

  arguments_list_jobs = {
    for job, details in local.scripts_dir_path_list_jobs :
    job => {
      "arguments" = fileexists(format("%s/arguments.yaml", details.script_dir_path)) ? lookup(yamldecode(file(format("%s/arguments.yaml", details.script_dir_path))), "${local.tags.environment}", null) : null
    }
  }
}

module "aws-glue-catalog" {
  source = "git::https://github.com/netexknowledge/platform-serverless-terraform-modules.git//aws-glue-catalog?ref=aws-glue-catalog@1"

  for_each = lookup(lookup(var.glue, "catalog", {}), "databases", {}) != {} ? lookup(var.glue.catalog, "databases", {}) : {}

  name         = each.key
  description  = lookup(each.value, "description", null)
  location_uri = lookup(each.value, "location_uri", null) != null ? lookup(local.properties, each.value.location_uri, each.value.location_uri) : null

  tags = local.tags
}

module "aws-glue-catalog-table" {
  source = "git::https://github.com/netexknowledge/platform-serverless-terraform-modules.git//aws-glue-catalog-table?ref=aws-glue-catalog-table@1"

  for_each = lookup(lookup(var.glue, "catalog", {}), "tables", {}) != {} ? lookup(var.glue.catalog, "tables", {}) : {}

  name             = each.key
  description      = lookup(each.value, "description", "")
  database_name    = lookup(each.value, "catalog_database", null) != null ? module.aws-glue-catalog[each.value.catalog_database].catalog_database.name : each.value.database_name
  catalog_id       = lookup(each.value, "catalog_id", null) != null ? lookup(local.properties, each.value.catalog_id, each.value.catalog_id) : null
  table_type       = lookup(each.value, "table_type", "EXTERNAL_TABLE") != "EXTERNAL_TABLE" ? lookup(local.properties, each.value.table_type, each.value.table_type) : "EXTERNAL_TABLE"
  owner            = lookup(each.value, "owner", null) != null ? lookup(local.properties, each.value.owner, each.value.owner) : null
  retention        = lookup(each.value, "retention", 0) != 0 ? lookup(local.properties, tostring(each.value.retention), each.value.retention) : 0
  target_table     = lookup(each.value, "target_table", null) != null ? lookup(local.properties, each.value.target_table, each.value.target_table) : null
  data_format      = lookup(each.value, "data_format", "csv") != "csv" ? lookup(local.properties, each.value.data_format, each.value.data_format) : "csv"
  parameters       = lookup(each.value, "parameters", {}) != {} ? can(tostring(each.value.parameters)) ? lookup(local.properties, each.value.parameters, {}) : each.value.parameters : {}
  serde_parameters = lookup(each.value, "serde_parameters", {}) != {} ? can(tostring(each.value.serde_parameters)) ? lookup(local.properties, each.value.serde_parameters, {}) : each.value.serde_parameters : {}
  location         = lookup(each.value, "location", null) != null ? lookup(local.properties, each.value.location, each.value.location) : null
  schema           = lookup(each.value, "schema", []) != [] ? can(tostring(each.value.schema)) ? lookup(local.properties, each.value.schema, []) : tolist(each.value.schema) : []
  partition_keys   = lookup(each.value, "partition_keys", []) != [] ? can(tostring(each.value.partition_keys)) ? lookup(local.properties, each.value.partition_keys, []) : tolist(each.value.partition_keys) : []
  partition_index  = lookup(each.value, "partition_index", null) != null ? can(tostring(each.value.partition_index)) ? lookup(local.properties, each.value.partition_index, null) : each.value.partition_index : null

  tags = local.tags
}

module "glue_connections" {
  source = "git::https://github.com/netexknowledge/platform-serverless-terraform-modules.git//aws-glue-connection?ref=aws-glue-connection@1"

  for_each = lookup(var.glue, "connections", {})

  name                     = each.key
  description              = lookup(each.value, "description", "")
  catalog_id               = lookup(each.value, "catalog_id", null) != null ? lookup(local.properties, each.value.catalog_id, each.value.catalog_id) : null
  connection_type          = lookup(each.value, "connection_type", "JDBC") != "JDBC" ? lookup(local.properties, each.value.connection_type, each.value.connection_type) : "JDBC"
  custom_connection_type   = lookup(each.value, "custom_connection_type", "") != "" ? lookup(local.properties, each.value.custom_connection_type, each.value.custom_connection_type) : ""
  jdbc_connection_url      = lookup(each.value, "jdbc_connection_url", "") != "" ? lookup(local.properties, each.value.jdbc_connection_url, each.value.jdbc_connection_url) : ""
  connection_url           = lookup(each.value, "connection_url", "") != "" ? lookup(local.properties, each.value.connection_url, each.value.connection_url) : ""
  jdbc_enforce_ssl         = lookup(each.value, "jdbc_enforce_ssl", false) != false ? lookup(local.properties, tostring(each.value.jdbc_enforce_ssl), each.value.jdbc_enforce_ssl) : false
  secret_name              = lookup(each.value, "secret_name", "") != "" ? lookup(local.properties, each.value.secret_name, each.value.secret_name) : ""
  username                 = lookup(each.value, "username", "") != "" ? lookup(local.properties, each.value.username, each.value.username) : ""
  password                 = lookup(each.value, "password", "") != "" ? lookup(local.properties, each.value.password, each.value.password) : ""
  connector_url            = lookup(each.value, "connector_url", "") != "" ? lookup(local.properties, each.value.connector_url, each.value.connector_url) : ""
  connector_class_name     = lookup(each.value, "connector_class_name", "") != "" ? lookup(local.properties, each.value.connector_class_name, each.value.connector_class_name) : ""
  s3_create_bucket_drivers = lookup(each.value, "s3_create_bucket_drivers", false) != false ? lookup(local.properties, tostring(each.value.s3_create_bucket_drivers), each.value.s3_create_bucket_drivers) : false
  s3_bucket_drivers_name   = lookup(each.value, "s3_bucket_drivers_name", "") != "" ? lookup(local.properties, each.value.s3_bucket_drivers_name, each.value.s3_bucket_drivers_name) : ""
  subnet_id                = lookup(each.value, "subnet_id", null) != null ? lookup(local.properties, each.value.subnet_id, each.value.subnet_id) : null
  security_group_id_list   = lookup(each.value, "security_group_id_list", []) != [] ? can(tostring(each.value.security_group_id_list)) ? lookup(local.properties, each.value.security_group_id_list, []) : tolist(each.value.security_group_id_list) : []
  match_criteria           = lookup(each.value, "match_criteria", []) != [] ? can(tostring(each.value.match_criteria)) ? lookup(local.properties, each.value.match_criteria, []) : tolist(each.value.match_criteria) : []

  tags = local.tags
}

module "glue_jobs" {
  source = "git::https://github.com/netexknowledge/platform-serverless-terraform-modules.git//aws-glue-job?ref=aws-glue-job@1"

  for_each = lookup(var.glue, "jobs", {})

  name = each.key

  glue_version = lookup(each.value, "glue_version", "3.0") != "3.0" ? lookup(local.properties, each.value.glue_version, each.value.glue_version) : "3.0"
  worker_type  = lookup(each.value, "worker_type", "G.1X") != "G.1X" ? lookup(local.properties, each.value.worker_type, each.value.worker_type) : "G.1X"

  script_file_path                  = lookup(each.value, "script_file_path", null)
  s3_create_bucket_glue             = lookup(each.value, "s3_create_bucket_glue", false)
  s3_bucket_glue_name               = lookup(each.value, "s3_bucket_glue_name", null) != null ? lookup(module.s3, each.value.s3_bucket_glue_name, null) != null ? module.s3[each.value.s3_bucket_glue_name].bucket_id : each.value.s3_bucket_glue_name : null
  custom_script_location_object_key = lookup(each.value, "custom_script_location_object_key", "")

  number_of_workers   = lookup(each.value, "number_of_workers", 2) != 2 ? lookup(local.properties, tostring(each.value.number_of_workers), each.value.number_of_workers) : 2
  execution_class     = lookup(each.value, "execution_class", "STANDARD") != "STANDARD" ? lookup(local.properties, each.value.execution_class, each.value.execution_class) : "STANDARD"
  max_retries         = lookup(each.value, "max_retries", 0) != 0 ? lookup(local.properties, tostring(each.value.max_retries), each.value.max_retries) : 0
  timeout             = lookup(each.value, "timeout", 2880) != 2880 ? lookup(local.properties, tostring(each.value.timeout), each.value.timeout) : 2880
  max_concurrent_runs = lookup(each.value, "max_concurrent_runs", 1) != 1 ? lookup(local.properties, tostring(each.value.max_concurrent_runs), each.value.max_concurrent_runs) : 1
  connections         = local.connections_list_id[each.key]

  job_language                        = lookup(each.value, "job_language", "python") != "python" ? lookup(local.properties, each.value.job_language, each.value.job_language) : "python"
  auto_scale_within_microbatch        = lookup(each.value, "auto_scale_within_microbatch", false) != false ? lookup(local.properties, tostring(each.value.auto_scale_within_microbatch), each.value.auto_scale_within_microbatch) : false
  enable_job_insights                 = lookup(each.value, "enable_job_insights", false) != false ? lookup(local.properties, tostring(each.value.enable_job_insights), each.value.enable_job_insights) : false
  job_bookmark_option                 = lookup(each.value, "job_bookmark_option", "job-bookmark-disable") != "job-bookmark-disable" ? lookup(local.properties, each.value.job_bookmark_option, each.value.job_bookmark_option) : "job-bookmark-disable"
  enable_metrics                      = lookup(each.value, "enable_metrics", false) != false ? lookup(local.properties, tostring(each.value.enable_metrics), each.value.enable_metrics) : false
  enable_observability_metrics        = lookup(each.value, "enable_observability_metrics", false) != false ? lookup(local.properties, tostring(each.value.enable_observability_metrics), each.value.enable_observability_metrics) : false
  enable_continuous_cloudwatch_log    = lookup(each.value, "enable_continuous_cloudwatch_log", false) != false ? lookup(local.properties, tostring(each.value.enable_continuous_cloudwatch_log), each.value.enable_continuous_cloudwatch_log) : false
  enable_spark_ui                     = lookup(each.value, "enable_spark_ui", false) != false ? lookup(local.properties, tostring(each.value.enable_spark_ui), each.value.enable_spark_ui) : false
  enable_continuous_log_filter        = lookup(each.value, "enable_continuous_log_filter", false) != false ? lookup(local.properties, tostring(each.value.enable_continuous_log_filter), each.value.enable_continuous_log_filter) : false
  enable_continuous_log_log_group     = lookup(each.value, "enable_continuous_log_log_group", "") != "" ? lookup(local.properties, each.value.enable_continuous_log_log_group, each.value.enable_continuous_log_log_group) : ""
  enable_continuous_log_stream_name   = lookup(each.value, "enable_continuous_log_stream_name", "") != "" ? lookup(local.properties, each.value.enable_continuous_log_stream_name, each.value.enable_continuous_log_stream_name) : ""
  enable_continuous_log_start_pattern = lookup(each.value, "enable_continuous_log_start_pattern", "") != "" ? lookup(local.properties, each.value.enable_continuous_log_start_pattern, each.value.enable_continuous_log_start_pattern) : ""
  enable_glue_datacatalog             = lookup(each.value, "enable_glue_datacatalog", true) != true ? lookup(local.properties, tostring(each.value.enable_glue_datacatalog), each.value.enable_glue_datacatalog) : true

  tags = local.tags
}

module "glue_crawler" {
  source = "git::https://github.com/netexknowledge/platform-serverless-terraform-modules.git//aws-glue-crawler?ref=aws-glue-crawler@1"

  for_each = lookup(var.glue, "crawlers", {})

  name                       = each.key
  type                       = lookup(each.value, "type", null) != null ? lookup(local.properties, each.value.type, each.value.type) : null
  description                = lookup(each.value, "description", "")
  database_name              = lookup(each.value, "catalog_database", null) == null ? each.value.database_name : module.aws-glue-catalog[each.value.catalog_database].catalog_database.name
  role_arn                   = try(module.glue_jobs[each.value.job_role].role.arn, each.value.role_arn)
  connection_name            = lookup(each.value, "connection", null) != null ? module.glue_connections[each.value.connection].glue_connection.name : null
  classifiers                = lookup(each.value, "classifiers", []) != [] ? can(tostring(each.value.classifiers)) ? lookup(local.properties, each.value.classifiers, []) : tolist(each.value.classifiers) : []
  path                       = lookup(each.value, "path", null) != null ? lookup(local.properties, each.value.path, each.value.path) : null
  tables                     = lookup(each.value, "tables", []) != [] ? can(tostring(each.value.tables)) ? lookup(local.properties, each.value.tables, []) : tolist(each.value.tables) : []
  exclusions                 = lookup(each.value, "exclusions", []) != [] ? can(tostring(each.value.exclusions)) ? lookup(local.properties, each.value.exclusions, []) : tolist(each.value.exclusions) : []
  scan_all                   = lookup(each.value, "scan_all", true) != true ? lookup(local.properties, tostring(each.value.scan_all), each.value.scan_all) : true
  enable_additional_metadata = lookup(each.value, "enable_additional_metadata", []) != [] ? can(tostring(each.value.enable_additional_metadata)) ? lookup(local.properties, each.value.enable_additional_metadata, []) : tolist(each.value.enable_additional_metadata) : []
  database_name_target       = lookup(each.value, "database_name_target", null) != null ? lookup(local.properties, each.value.database_name_target, each.value.database_name_target) : null
  schedule                   = lookup(each.value, "schedule", null) != null ? lookup(local.properties, each.value.schedule, each.value.schedule) : null

  tags = local.tags
}

resource "aws_iam_policy" "glue_secret_policy" {
  for_each = { for job, secrets in local.connections_list_secretname : job => secrets if length(secrets) > 0 }

  name        = format("%s-%s-glue-secrets-%s-policy", var.tags["product"], local.tags.environment, each.key)
  description = "IAM policy for glue job to access secrets manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue"
        Effect   = "Allow"
        Resource = [for secret in each.value : "arn:aws:secretsmanager:${var.aws_region}:${local.aws_account_id}:secret:${lookup(secret, "secret_name", "") != "" ? lookup(local.properties, secret.secret_name, secret.secret_name) : ""}-*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_secret_policy_attachment" {
  for_each = { for job, secrets in local.connections_list_secretname : job => secrets if length(secrets) > 0 }

  role       = module.glue_jobs[each.key].role.name
  policy_arn = aws_iam_policy.glue_secret_policy[each.key].arn
}

resource "aws_security_group_rule" "glue_security_group_rule" {
  for_each = { for sg_id in local.connections_sg_ids : sg_id => sg_id }

  security_group_id = each.value
  description       = "Allow all inbound traffic from the security group itself for Glue connections"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
}

module "glue_trigger" {
  source = "git::https://github.com/netexknowledge/platform-serverless-terraform-modules.git//aws-glue-trigger?ref=aws-glue-trigger@1"

  for_each = local.triggers_list

  name        = each.key
  description = lookup(each.value.config, "description", "")
  enabled     = lookup(each.value.config, "enabled", true) != true ? lookup(local.properties, tostring(each.value.config.enabled), each.value.config.enabled) : true
  schedule    = lookup(each.value.config, "schedule", null) != null ? lookup(local.properties, each.value.config.schedule, each.value.config.schedule) : null
  actions = {
    job_name               = lookup(module.glue_jobs[each.value.job_name].job, "name", null),
    arguments              = merge(lookup(each.value.config, "arguments", null), local.arguments_list_jobs[each.value.job_name].arguments),
    timeout                = lookup(each.value.config, "timeout", null) != null ? lookup(local.properties, each.value.config.timeout, each.value.config.timeout) : null,
    security_configuration = lookup(each.value.config, "security_configuration", null) != null ? lookup(local.properties, each.value.config.security_configuration, each.value.config.security_configuration) : null,
    notify_delay_after     = lookup(each.value.config, "notify_delay_after", null) != null ? lookup(local.properties, each.value.config.notify_delay_after, each.value.config.notify_delay_after) : null
  }

  predicate = lookup(each.value.config, "predicate", null) != null ? lookup(local.properties, each.value.config.predicate, each.value.config.predicate) : null

  tags = local.tags
}

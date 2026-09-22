output "version" {
  description = "Version of Terrasam template"
  value       = "1.0.0"
}

output "api_logs_command" {
  description = "Command to view http api logs with sam"
  value       = length(module.api_gateway) > 0 ? "sam logs --cw-log-group ${module.api_gateway[0].cloudwatch_log_group_name} -t" : ""
}

output "lambdas_logs_command" {
  description = "Command to view lambda functions logs with sam"
  value = [
    for lambda_name, lambda_config in var.lambdas : "sam logs --cw-log-group ${module.lambda_functions[lambda_name].lambda_cloudwatch_log_group_name} -t"
  ]
}

output "lambda_function" {
  description = "Lambda function list"
  value = {
    for lambda_name, lambda_config in var.lambdas : lambda_name => {
      name = module.lambda_functions[lambda_name].lambda_function_name
      arn  = module.lambda_functions[lambda_name].lambda_function_arn
    }
  }
}

output "api_gateway" {
  description = "Api Gateway"
  value = length(module.api_gateway) > 0 ? {
    arn        = module.api_gateway[0].arn
    name       = module.api_gateway[0].name
    invoke_url = module.api_gateway_deployment[0].invoke_url
    custom_url = lookup(var.apigateway, "custom_domain", false) ? "https://${local.custom_domain_name}/${lookup(var.apigateway, "custom_base_path", "${local.tags.product}-${local.tags.project}-${var.apigateway.name}")}" : ""
  } : {}
}

output "dynamodb_table" {
  description = "DynamoDB table list"
  value = {
    for table_name, table_config in var.dynamodb.tables : table_name => {
      name = module.dynamodb[table_name].table_id
      arn  = module.dynamodb[table_name].table_arn
      table_stream_arn = module.dynamodb[table_name].table_stream_arn
    }
  }
}

output "s3_bucket" {
  description = "S3 bucket list"
  value = {
    for bucket_name, bucket_config in var.s3.buckets : bucket_name => {
      name   = module.s3[bucket_name].bucket_id
      arn    = module.s3[bucket_name].bucket_arn
      domain = module.s3[bucket_name].bucket_regional_domain_name
    }
  }
}

output "sqs" {
  description = "SQS list"
  value = {
    for sqs_name, sqs_config in var.sqs.queues : sqs_name => {
      arn  = module.sqs[sqs_name].queue_arn
      url  = module.sqs[sqs_name].queue_url
      deadletter_arn = module.sqs[sqs_name].deadletter_queue_arn
      deadletter_url = module.sqs[sqs_name].deadletter_queue_url
    }
  }
}

output "sns" {
  description = "SNS list"
  value = {
    for sns_name, sns_config in var.sns.topics : sns_name => {
      name = module.sns[sns_name].topic_id
      arn  = module.sns[sns_name].topic_arn
    }
  }
}

output "glue_catalog" {
  description = "Glue catalog"
  value = {
    for database_name, database_config in lookup(lookup(var.glue, "catalog", {}), "databases", {}) : database_name => {
      name       = module.aws-glue-catalog[database_name].catalog_database.name
      arn        = module.aws-glue-catalog[database_name].catalog_database.arn
      id         = module.aws-glue-catalog[database_name].catalog_database.id
      catalog_id = module.aws-glue-catalog[database_name].catalog_database.catalog_id
    }
  }
}

output "glue_catalog_table" {
  description = "Glue catalog table list"
  value = {
    for table_name, table_config in lookup(lookup(var.glue, "catalog", {}), "tables", {}) : table_name => module.aws-glue-catalog-table[table_name]
  }
}

output "glue_job" {
  description = "Glue job list"
  value = {
    for job_name, job_config in lookup(var.glue, "jobs", {}) : job_name => {
      name              = module.glue_jobs[job_name].job.name
      arn               = module.glue_jobs[job_name].job.arn
      id                = module.glue_jobs[job_name].job.id
      script_location   = module.glue_jobs[job_name].job.command[0].script_location
      default_arguments = module.glue_jobs[job_name].job.default_arguments
    }
  }
}

output "glue_crawler" {
  description = "Glue crawler list"
  value = {
    for crawler_name, crawler_config in lookup(var.glue, "crawlers", {}) : crawler_name => {
      name          = module.glue_crawler[crawler_name].crawler.name
      arn           = module.glue_crawler[crawler_name].crawler.arn
      id            = module.glue_crawler[crawler_name].crawler.id
      database_name = module.glue_crawler[crawler_name].crawler.database_name
    }
  }
}

output "glue_connections" {
  description = "Glue connections list"
  value = {
    for connection_name, connection_config in lookup(var.glue, "connections", {}) : connection_name => {
      id               = module.glue_connections[connection_name].glue_connection.id
      arn              = module.glue_connections[connection_name].glue_connection.arn
      s3_object_driver = module.glue_connections[connection_name].s3_object_driver
    }
  }
}

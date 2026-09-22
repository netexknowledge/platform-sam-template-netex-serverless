data "external" "env_vars" {
  for_each = var.lambdas

  program = ["bash", "-c", <<-EOT
    file_path="${path.module}/${each.value.source_path}/${local.tags.environment}.env"
    if [ ! -f "$file_path" ]; then
      echo "{}"
    else
      awk -F'=' '{
        gsub(/^[ \t]+|[ \t]+$/, "", $1);   # Trim leading and trailing whitespace from key
        val = substr($0, index($0, $2));   # Extract the value string starting from the first character of $2
        gsub(/^[ \t]+/, "", val);          # Trim leading whitespace from the value
        gsub(/^"|"$/, "", val);            # Remove the leading and trailing quotes from the value, if any
        if(NR>1) printf(", ");             # Print comma between items
        printf "\"%s\":\"%s\"", $1, val;   # Print the key-value pair
      }' $file_path | awk 'BEGIN {print "{"} {print} END {print "}"}'
    fi
  EOT
  ]
}

locals {
  environment_variables = {
    for lambda_name, lambda_config in var.lambdas : lambda_name =>
    merge(
      lookup(lambda_config, "environment_variables", {}),
      data.external.env_vars[lambda_name].result
    )
  }

  lambdas_allowed_triggers = {
    for lambda_name, lambda_config in var.lambdas : lambda_name =>
    merge(
      lookup(lambda_config, "allowed_triggers_custom", {}) != {} ? can(tostring(lambda_config.allowed_triggers_custom)) ? lookup(local.properties, lambda_config.allowed_triggers_custom, {}) : can(tostring(lambda_config.allowed_triggers_custom)) ? {} : lambda_config.allowed_triggers_custom : {},
      # If allowed triggers without key to use in centralized lambda authorizer config
      can(length(lambda_config.allowed_triggers.apigateway) > 0) ? length(module.api_gateway) == 0 ? {
        "AllowApiGatewayApiAuth" = {
          service    = "apigateway",
          source_arn = "arn:aws:execute-api:${local.aws_region}:${local.aws_account_id}:*/*/*"
        }
      } : {} : {},
      # If 'allowed_triggers' exists and contains 'apigateway', create a corresponding entry
      { for pair in flatten([
        for type, config in lookup(lambda_config, "allowed_triggers", {}) :
        [for api in keys(config) :
          {
            key = "Allow${title(type)}${title(api)}"
            value = {
              service    = type,
              source_arn = "${module.api_gateway[0].execution_arn}/*/*"
            }
        } if type == "apigateway"]
      ]) : pair.key => pair.value },
      # If 'allowed_triggers' exists and contains 's3', create a corresponding entry
      { for pair in flatten([
        for type, config in lookup(lambda_config, "allowed_triggers", {}) :
        [for bucket in keys(config) :
          {
            key = "Allow${title(type)}${title(bucket)}"
            value = {
              service    = type,
              source_arn = "${module.s3[bucket].bucket_arn}"
            }
        } if type == "s3"]
      ]) : pair.key => pair.value },
      # If 'allowed_triggers' exists and contains 'sqs', create a corresponding entry
      { for pair in flatten([
        for type, config in lookup(lambda_config, "allowed_triggers", {}) :
        [for queue in keys(config) :
          {
            key = "Allow${title(type)}${title(queue)}"
            value = {
              service              = type,
              source_arn           = "${module.sqs[queue].queue_arn}"
              event_source_mapping = lookup(config[queue], "event_source_mapping", {})
            }
        } if type == "sqs"]
      ]) : pair.key => pair.value },
      # If 'allowed_triggers' exists and contains 'sns', create a corresponding entry
      { for pair in flatten([
        for type, config in lookup(lambda_config, "allowed_triggers", {}) :
        [for topic in keys(config) :
          {
            key = "Allow${title(type)}${title(topic)}"
            value = {
              service    = type,
              source_arn = "${module.sns[topic].topic_arn}"
            }
        } if type == "sns"]
      ]) : pair.key => pair.value }
    )
  }

  lambdas_policy_statements = {
    for lambda_name, lambda_config in var.lambdas : lambda_name =>
    merge(
      # Allow execute-api Invoke and ManageConnections
      can(length(lambda_config.allowed_triggers.apigateway) > 0) ? {
        "allow_apigateway_invoke" = {
          effect    = "Allow"
          actions   = ["execute-api:Invoke", "execute-api:ManageConnections"]
          resources = length(module.api_gateway) > 0 ? ["${module.api_gateway[0].execution_arn}/*/*"] : ["arn:aws:execute-api:${local.aws_region}:${local.aws_account_id}:*/*/*"]
        }
      } : {},
      # Custom policy statements
      lookup(lambda_config, "policy_statements_custom", {}),
      # Flatten and merge generated policy statements type DynamoDB
      { for pair in flatten([
        for type, config in lookup(lambda_config, "policy_statements", {}) :
        [for table in keys(config) :
          {
            key = "${lower(type)}_${lower(table)}",
            value = {
              effect    = lookup(config[table], "effect", "Allow"),
              actions   = lookup(config[table], "actions", ["dynamodb:*"]),
              resources = [module.dynamodb[table].table_arn]
            }
        } if type == "dynamodb"]
      ]) : pair.key => pair.value },
      # Flatten and merge generated policy statements type S3
      { for pair in flatten([
        for type, config in lookup(lambda_config, "policy_statements", {}) :
        [for bucket in keys(config) :
          {
            key = "${lower(type)}_${lower(bucket)}",
            value = {
              effect    = lookup(config[bucket], "effect", "Allow"),
              actions   = lookup(config[bucket], "actions", ["s3:*", "s3-object-lambda:*"]),
              resources = [module.s3[bucket].bucket_arn, "${module.s3[bucket].bucket_arn}/*"]
            }
        } if type == "s3"]
      ]) : pair.key => pair.value },
      # Flatten and merge generated policy statements type SQS
      { for pair in flatten([
        for type, config in lookup(lambda_config, "policy_statements", {}) :
        [for queue in keys(config) :
          {
            key = "${lower(type)}_${lower(queue)}",
            value = {
              effect    = lookup(config[queue], "effect", "Allow"),
              actions   = lookup(config[queue], "actions", ["sqs:*"]),
              resources = [module.sqs[queue].queue_arn]
            }
        } if type == "sqs"]
      ]) : pair.key => pair.value },
      # Flatten and merge generated policy statements type SNS
      { for pair in flatten([
        for type, config in lookup(lambda_config, "policy_statements", {}) :
        [for topic in keys(config) :
          {
            key = "${lower(type)}_${lower(topic)}",
            value = {
              effect    = lookup(config[topic], "effect", "Allow"),
              actions   = lookup(config[topic], "actions", ["sns:*"]),
              resources = [module.sns[topic].topic_arn]
            }
        } if type == "sns"]
      ]) : pair.key => pair.value },
      # Flatten and merge generated policy statements for AWS Secrets Manager
      { for key, value in local.environment_variables[lambda_name] :
        "${lower(key)}_scmssm" => {
          effect    = "Allow",
          actions   = ["secretsmanager:GetSecretValue", "ssm:GetParameter"],
          resources = ["arn:aws:secretsmanager:${local.aws_region}:${local.aws_account_id}:secret:${value}*", "arn:aws:ssm:${local.aws_region}:${local.aws_account_id}:parameter${value}"]
        } if substr(key, 0, 11) == "AWS_SECRET_" && length(value) > 8
      }
    )
  }

  enable_secrets_layers = {
    for lambda_name, lambda_config in var.lambdas : lambda_name =>
    anytrue([
      for key in keys(local.environment_variables[lambda_name]) :
      substr(key, 0, 11) == "AWS_SECRET_"
    ])
  }

}

module "lambda_functions" {
  source = "git::https://github.com/netexknowledge/platform-serverless-terraform-modules.git//aws-lambda?ref=aws-lambda@1"

  for_each = var.lambdas

  version_lambda        = var.project_version
  version_lambda_suffix = var.pipelinesuffixversion
  parameters = merge(
    each.value,
    { environment_variables = local.environment_variables[each.key] }
  )
  allowed_triggers  = local.lambdas_allowed_triggers[each.key]
  policy_statements = local.lambdas_policy_statements[each.key]
  add_secrets_layer = lookup(local.enable_secrets_layers, each.key, false)
  add_datadog_layer = var.pipelineobservability ? true : lookup(each.value, "add_datadog_layer", false)

  vpc_security_group_ids = local.vpc_security_group_ids
  vpc_subnet_ids         = local.vpc_subnet_ids

  tags = local.tags
}

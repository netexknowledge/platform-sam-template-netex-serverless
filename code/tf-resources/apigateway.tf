locals {
  tfvars_content = file("${path.module}/terraform.tfvars")

  has_authorizer = can(regex("\"?authorizer\"?\\s*=\\s*true", local.tfvars_content)) ? true : lookup(var.apigateway, "authorizer", null) != null ? true : false

  single_resources = lookup(var.apigateway, "type", null) == "REST" ? [
    for path, path_details in lookup(var.apigateway, "resources", {}) :
    { "${path}" = [{
      lambda_name          = lookup(path_details, "lambda_name", null),
      sqs_name             = lookup(path_details, "sqs_name", null),
      http_method          = lookup(path_details, "http_method", []),
      authorizer           = lookup(path_details, "authorizer", null),
      authorizer_id        = lookup(path_details, "authorizer_id", null),
      timeout_milliseconds = lookup(path_details, "timeout_milliseconds", null),
    }] } if try(path_details["http_method"], null) != null
  ] : []

  complex_resources = lookup(var.apigateway, "type", null) == "REST" ? [
    for path, path_details in lookup(var.apigateway, "resources", {}) :
    { "${path}" = path_details } if try(path_details["http_method"], null) == null
  ] : []

  all_resources = concat(local.single_resources, local.complex_resources)

  resources = merge(local.all_resources...)
}

module "api_gateway" {
  source = "git::https://github.com/netexknowledge/platform-serverless-terraform-modules.git//aws-apigateway?ref=aws-apigateway@1"

  count = var.apigateway != {} ? 1 : 0

  type                         = var.apigateway.type
  name                         = var.apigateway.name
  endpoint_configuration_types = lookup(var.apigateway, "endpoint_type", "EDGE")
  binary_media_types           = lookup(var.apigateway, "binary_media_types", null)

  enable_cloudwatch_role = var.apigateway.enable_cloudwatch_role
  tags                   = local.tags
}

module "api_gateway_authorizer" {
  source = "git::https://github.com/netexknowledge/platform-serverless-terraform-modules.git//aws-apigateway-authorizer?ref=aws-apigateway-authorizer@1"

  count = local.has_authorizer ? 1 : 0

  type                       = var.apigateway.type
  name                       = contains(keys(var.apigateway), "authorizer") ? lookup(var.apigateway.authorizer, "lambda_name", null) : null
  parameters                 = lookup(var.apigateway, "authorizer", null)
  api_name                   = module.api_gateway[0].name
  api_id                     = module.api_gateway[0].id
  lambda_function_invoke_arn = contains(keys(var.apigateway), "authorizer") ? contains(keys(var.apigateway.authorizer), "lambda_name") ? module.lambda_functions[var.apigateway.authorizer.lambda_name].lambda_function_invoke_arn : null : null
  lambda_function_arn        = contains(keys(var.apigateway), "authorizer") ? contains(keys(var.apigateway.authorizer), "lambda_name") ? module.lambda_functions[var.apigateway.authorizer.lambda_name].lambda_function_arn : null : null

  tags = local.tags
}

module "api_gateway_resources" {
  source = "git::https://github.com/netexknowledge/platform-serverless-terraform-modules.git//aws-apigateway-resource?ref=aws-apigateway-resource@1"

  for_each = lookup(var.apigateway, "resources", {})

  type = var.apigateway.type
  name = each.key
  parameters = lookup(var.apigateway, "type", null) == "REST" ? {
    http_method          = distinct(flatten([for resource in local.resources[each.key] : resource.http_method])),
    authorizer           = try(local.resources[each.key][0].authorizer, null),
    authorizer_id        = try(local.resources[each.key][0].authorizer_id, null)
    timeout_milliseconds = try(local.resources[each.key][0].timeout_milliseconds, null)
    } : {
    http_method          = lookup(each.value, "http_method", []),
    authorizer           = lookup(each.value, "authorizer", null)
    authorizer_id        = lookup(each.value, "authorizer_id", null)
    timeout_milliseconds = lookup(each.value, "timeout_milliseconds", null)
  }
  api_id                     = module.api_gateway[0].id
  api_root_resource_id       = module.api_gateway[0].root_resource_id
  api_role_arn               = module.api_gateway[0].role_arn
  api_gateway_authorizer_id  = length(module.api_gateway_authorizer) > 0 ? module.api_gateway_authorizer[0].id : null
  lambda_function_invoke_arn = lookup(var.apigateway, "type", null) == "REST" ? null : module.lambda_functions[each.value.lambda_name].lambda_function_invoke_arn
  lambda_function_invoke_arns_by_method = lookup(var.apigateway, "type", null) == "REST" ? merge([
    for resource in local.resources[each.key] :
    { for method in resource.http_method : method => lookup(resource, "sqs_name", null) == null ? module.lambda_functions[resource.lambda_name].lambda_function_invoke_arn : module.sqs[resource.sqs_name].apigateway_invoke_queue_arn }
  ]...) : null
  authorizer_by_method = lookup(var.apigateway, "type", null) == "REST" ? merge([
    for resource in local.resources[each.key] :
    { for method in resource.http_method : method => {
      authorizer    = lookup(resource, "authorizer", null),
      authorizer_id = lookup(resource, "authorizer_id", null)
    } }
  ]...) : null

  request_mapping_template = can(lookup(each.value, "request_mapping_template")) ? lookup(each.value, "request_mapping_template", "Action=SendMessage&MessageBody=$util.urlEncode($input.body)") : null

  tags = local.tags
}

module "api_gateway_deployment" {
  source = "git::https://github.com/netexknowledge/platform-serverless-terraform-modules.git//aws-apigateway-deployment?ref=aws-apigateway-deployment@1"

  count = var.apigateway != {} ? 1 : 0

  type                     = var.apigateway.type
  api_id                   = module.api_gateway[0].id
  stage_name               = lookup(var.apigateway, "stage_name", "$default")
  cloudwatch_log_group_arn = module.api_gateway[0].cloudwatch_log_group_arn
  enable_cloudwatch_role   = var.apigateway.enable_cloudwatch_role
  custom_domain            = lookup(var.apigateway, "custom_domain", false)
  base_path                = lookup(var.apigateway, "custom_base_path", "${local.tags.product}-${local.tags.project}-${var.apigateway.name}")
  custom_domain_name       = local.custom_domain_name

  depends_on = [
    module.api_gateway_resources,
    module.lambda_functions
  ]

  tags = local.tags
}

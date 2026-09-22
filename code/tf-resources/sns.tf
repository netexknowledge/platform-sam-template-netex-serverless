locals {

  lambda_sns_subscriptions = {
    for lambda_name, lambda_config in var.lambdas : lambda_name =>
    merge(
      # Flatten and merge generated policy statements type SNS
      { for pair in flatten([
        for type, config in lookup(lambda_config, "allowed_triggers", {}) :
        [for topic in keys(config) :
          {
            key = "${topic}",
            value = {
              topic_name  = "${topic}",
              lambda_name = "${lambda_name}"

            }
        } if type == "sns"]
      ]) : pair.key => pair.value }
    )
  }

  sns_lambda_subscriptions = {
    for topic in keys(var.sns.topics) : topic =>
    merge(
      { for pair in flatten([
        for lambda_name, subscription in local.lambda_sns_subscriptions :
        {
          key   = "${title(lambda_name)}${title(topic)}",
          value = lookup(subscription, "${topic}", {})
        }
      ]) : pair.key => pair.value }
    )
  }

  flattened_sns_lambda_subscriptions = merge([
    for topic, subscriptions in local.sns_lambda_subscriptions : {
      for subscription_name, subscription_details in subscriptions : subscription_name => subscription_details
    }
  ]...)

}

module "sns" {
  source = "git::https://github.com/netexknowledge/platform-serverless-terraform-modules.git//aws-sns?ref=aws-sns@1"

  for_each = var.sns.topics

  name = each.key

  delivery_policy             = lookup(each.value, "delivery_policy", null)
  fifo_topic                  = lookup(each.value, "fifo_topic", false)
  content_based_deduplication = lookup(each.value, "content_based_deduplication", false)

  tags = local.tags
}

resource "aws_sns_topic_subscription" "sns_lambda_subscriptions" {
  for_each = { for k, v in local.flattened_sns_lambda_subscriptions : k => v if length(lookup(v, "lambda_name", [])) > 0 }

  protocol  = "lambda"
  topic_arn = module.sns[each.value.topic_name].topic_arn
  endpoint  = module.lambda_functions[each.value.lambda_name].lambda_function_arn
}

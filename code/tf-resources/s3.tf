locals {

  lambda_s3_notifications = {
    for lambda_name, lambda_config in var.lambdas : lambda_name =>
    merge(
      # Flatten and merge generated policy statements type S3
      { for pair in flatten([
        for type, config in lookup(lambda_config, "allowed_triggers", {}) :
        [for bucket in keys(config) :
          {
            key = "${bucket}",
            value = {
              bucket_name = "${bucket}",
              lambda_name = "${lambda_name}",
              notifications = [
                for notification in lookup(config[bucket], "notifications", [{
                  events        = ["s3:ObjectCreated:*"],
                  filter_prefix = null,
                  filter_suffix = null
                }]) :
                {
                  events        = lookup(notification, "events", ["s3:ObjectCreated:*"]),
                  filter_prefix = lookup(notification, "filter_prefix", null),
                  filter_suffix = lookup(notification, "filter_suffix", null)
                }
              ]
            }
        } if type == "s3"]
      ]) : pair.key => pair.value }
    )
  }

  s3_lambda_notifications = {
    for bucket in keys(var.s3.buckets) : bucket =>
    merge(
      { for pair in flatten([
        for lambda_name, notification in local.lambda_s3_notifications :
        {
          key   = "${title(lambda_name)}${title(bucket)}",
          value = lookup(notification, "${bucket}", {})
        }
      ]) : pair.key => pair.value }
    )
  }

  flattened_s3_lambda_notifications = merge([
    for bucket, notifications in local.s3_lambda_notifications : {
      for notification_name, notification_details in notifications : notification_name => notification_details
    }
  ]...)

}

module "s3" {
  source = "git::https://github.com/netexknowledge/platform-serverless-terraform-modules.git//aws-s3?ref=aws-s3@1"

  for_each = var.s3.buckets

  bucket          = each.key
  public_access   = lookup(each.value, "public_access", false)
  acl             = lookup(each.value, "acl", "private")
  versioning      = lookup(each.value, "versioning", false)
  prevent_destroy = lookup(each.value, "prevent_destroy", false)
  lifecycle_rules = lookup(each.value, "lifecycle_rules", [])
  cors_rules      = lookup(each.value, "cors_rules", [])

  tags = local.tags
}

data "aws_sns_topic" "s3_object_default_events" {
  count = (local.tags.environment != "tmp") ? 1 : 0

  name = format("s3-object-events-%s-topic", local.tags.environment)
}

resource "aws_s3_bucket_notification" "bucket_event_default" {
  for_each = (
    length(data.aws_sns_topic.s3_object_default_events) > 0 ?
    {
      for bucket_name, bucket_config in var.s3.buckets : bucket_name => bucket_name
      if alltrue([
        for lambda_config in local.s3_lambda_notifications[bucket_name] : length(keys(lambda_config)) == 0
      ])
    } : {}
  )

  bucket = module.s3[each.key].bucket_id

  topic {
    topic_arn = data.aws_sns_topic.s3_object_default_events[0].arn
    events    = ["s3:ObjectRestore:Completed"]
  }
}

resource "aws_s3_bucket_notification" "bucket_event" {
  for_each = { for k, v in local.flattened_s3_lambda_notifications : k => v if length(lookup(v, "notifications", [])) > 0 }

  bucket = module.s3[each.value["bucket_name"]].bucket_id

  dynamic "lambda_function" {
    for_each = each.value["notifications"]

    content {
      lambda_function_arn = module.lambda_functions[each.value["lambda_name"]].lambda_function_arn
      events              = lookup(lambda_function.value, "events", ["s3:ObjectCreated:*"])
      filter_prefix       = lookup(lambda_function.value, "filter_prefix", null)
      filter_suffix       = lookup(lambda_function.value, "filter_suffix", null)
    }
  }
}

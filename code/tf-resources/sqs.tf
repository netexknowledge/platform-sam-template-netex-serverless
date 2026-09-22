locals {

  lambda_sqs_events = {
    for lambda_name, lambda_config in var.lambdas : lambda_name =>
    merge(
      # Flatten and merge generated policy statements type SQS
      { for pair in flatten([
        for type, config in lookup(lambda_config, "allowed_triggers", {}) :
        [for queue in keys(config) :
          {
            key = "${queue}",
            value = {
              queue_name      = "${queue}",
              lambda_name     = "${lambda_name}",
              filter_criteria = lookup(config[queue], "filter_criteria", null)
            }
        } if type == "sqs" && length(lookup(lookup(local.lambdas_allowed_triggers[lambda_name], "AllowSqs${title(queue)}", {}), "event_source_mapping", {})) == 0]
      ]) : pair.key => pair.value }
    )
  }

  sqs_lambda_events = {
    for queue in keys(var.sqs.queues) : queue =>
    merge(
      { for pair in flatten([
        for lambda_name, event in local.lambda_sqs_events :
        {
          key   = "${title(lambda_name)}${title(queue)}",
          value = lookup(event, "${queue}", {})
        }
      ]) : pair.key => pair.value }
    ) if !lookup(var.sqs.queues[queue], "disabled", false)
  }

  flattened_sqs_lambda_events = merge([
    for queue, events in local.sqs_lambda_events : {
      for event_name, event_details in events : event_name => event_details
    }
  ]...)

}

module "sqs" {
  source = "git::https://git.netexlearning.com/exposed/serverless-terraform-modules.git//aws-sqs?ref=aws-sqs@1"

  for_each = var.sqs.queues

  name                        = each.key
  delay_seconds               = lookup(each.value, "delay_seconds", 0)
  redrive_max_receive_count   = lookup(each.value, "redrive_max_receive_count", null)
  max_message_size            = lookup(each.value, "max_message_size", 262144)
  message_retention_seconds   = lookup(each.value, "message_retention_seconds", 345600)
  receive_wait_time_seconds   = lookup(each.value, "receive_wait_time_seconds", 0)
  visibility_timeout_seconds  = lookup(each.value, "visibility_timeout_seconds", 30)
  fifo_queue                  = lookup(each.value, "fifo_queue", false)
  content_based_deduplication = lookup(each.value, "content_based_deduplication", false)
  fifo_throughput_limit       = lookup(each.value, "fifo_throughput_limit", "perMessageGroupId")

  tags = local.tags
}

resource "aws_lambda_event_source_mapping" "sqs_lambda_events" {
  for_each = { for k, v in local.flattened_sqs_lambda_events : k => v if length(lookup(v, "lambda_name", [])) > 0 }

  event_source_arn = module.sqs[each.value["queue_name"]].queue_arn
  function_name    = module.lambda_functions[each.value["lambda_name"]].lambda_function_arn

  enabled                            = lookup(var.sqs.queues[each.value["queue_name"]], "enabled", true)
  batch_size                         = lookup(var.sqs.queues[each.value["queue_name"]], "batch_size", 10)
  function_response_types            = lookup(var.sqs.queues[each.value["queue_name"]], "function_response_types", [])
  maximum_batching_window_in_seconds = lookup(var.sqs.queues[each.value["queue_name"]], "maximum_batching_window_in_seconds", null)

  dynamic "destination_config" {
    for_each = lookup(var.sqs.queues[each.value["queue_name"]], "destination_config_on_failure", null) != null ? [true] : []
    content {
      on_failure {
        destination_arn = lookup(var.sqs.queues[each.value["queue_name"]], "destination_config_on_failure", null)
      }
    }
  }

  dynamic "scaling_config" {
    for_each = lookup(var.sqs.queues[each.value["queue_name"]], "scaling_config", null) != null ? [true] : []
    content {
      maximum_concurrency = lookup(var.sqs.queues[each.value["queue_name"]].scaling_config, "maximum_concurrency", null)
    }
  }

  dynamic "metrics_config" {
    for_each = lookup(var.sqs.queues[each.value["queue_name"]], "metrics_config", null) != null ? [true] : []

    content {
      metrics = lookup(var.sqs.queues[each.value["queue_name"]].metrics_config, "metrics", null)
    }
  }

  dynamic "filter_criteria" {
    for_each = lookup(var.sqs.queues[each.value["queue_name"]], "filter_criteria", null) != null ? [true] : []

    content {
      dynamic "filter" {
        for_each = try(flatten([var.sqs.queues[each.value["queue_name"]].filter_criteria]), [])

        content {
          pattern = try(filter.value.pattern, null)
        }
      }
    }
  }
}

module "dynamodb" {
  source = "git::https://git.netexlearning.com/exposed/serverless-terraform-modules.git//aws-dynamodb?ref=aws-dynamodb@1"

  for_each = var.dynamodb.tables

  name           = each.key
  billing_mode   = lookup(each.value, "billing_mode", "PAY_PER_REQUEST")
  read_capacity  = lookup(each.value, "read_capacity", null)
  write_capacity = lookup(each.value, "write_capacity", null)
  attributes     = each.value.attributes
  hash_key       = each.value.hash_key
  autoscaling    = lookup(each.value, "autoscaling", {})

  tags = local.tags
}

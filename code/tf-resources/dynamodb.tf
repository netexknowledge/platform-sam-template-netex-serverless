module "dynamodb" {
  source = "git::https://github.com/netexknowledge/platform-serverless-terraform-modules.git//aws-dynamodb?ref=aws-dynamodb@1"

  for_each = var.dynamodb.tables

  name           = each.key
  billing_mode   = lookup(each.value, "billing_mode", "PAY_PER_REQUEST")
  read_capacity  = lookup(each.value, "read_capacity", null)
  write_capacity = lookup(each.value, "write_capacity", null)
  attributes     = each.value.attributes
  hash_key       = each.value.hash_key
  autoscaling    = lookup(each.value, "autoscaling", {})

  # Por defecto, toda tabla se replica en la region de DR que anuncie la
  # pipeline. Si platform-ops no anuncia ninguna -hoy, mientras no exista el
  # bloque "dr" en su config.json- la lista sale vacia y no cambia nada. Una
  # tabla concreta puede quedarse fuera poniendo replica_regions = [] en su
  # entrada del tfvars.
  replica_regions = lookup(each.value, "replica_regions", local.dr_regions)

  tags = local.tags
}

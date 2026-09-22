locals {
  aws_account_id = var.aws_account_id == null ? data.aws_caller_identity.current.account_id : var.aws_account_id
}

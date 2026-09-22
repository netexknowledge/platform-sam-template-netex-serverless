terraform {
  # backend "s3" {
  #   bucket = "netexserverless-terraform-state"
  #   key    = "product/serverless.tfstate"
  #   region = "eu-west-1"

  #   dynamodb_table = "terraform-netexserverless-lock"

  #   encrypt    = true
  #   kms_key_id = "arn:aws:kms:eu-west-1:xxxxx:alias/aws/s3"
  # }
}

provider "aws" {
  region = local.aws_region
}

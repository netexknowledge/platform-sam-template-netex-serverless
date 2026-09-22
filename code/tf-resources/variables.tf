variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_version" {
  description = "Project version"
  type        = string
  default     = "0.0.1"
}

variable "profile" {
  description = "AWS profile"
  type        = string
  default     = "default"
}

variable "config_location" {
  description = "AWS configuration file"
  type        = string
  default     = "~/.aws/config"
}

variable "creds_location" {
  description = "AWS credentials file"
  type        = string
  default     = "~/.aws/credentials"
}

variable "tags" {
  description = "values for tags"
  type        = map(string)
  default = {
    environment = "tmp"
    project     = "serverless"
    product     = "netex"
    terraform   = "true"
    samtemplate = "sam-template-netex-serverless"
  }
}

variable "lambdas" {
  description = "parameters of lambda functions"
  type        = any
  default     = {}
}

variable "apigateway" {
  description = "parameter of AWS API Gateway"
  type        = any
  default     = {}
}

variable "dynamodb" {
  description = "parameter of DynamoDB"
  type        = any
  default = {
    tables = {}
  }
}

variable "s3" {
  description = "parameter of S3"
  type        = any
  default = {
    buckets = {}
  }
}

variable "sqs" {
  description = "parameter of SQS"
  type        = any
  default = {
    queues = {}
  }
}

variable "sns" {
  description = "parameter of SNS"
  type        = any
  default = {
    topics = {}
  }
}

variable "temporaltags" {
  description = "Terraform tags values to use in temporal accounts"
  type        = map(string)
  default     = {}
}

variable "pipelinetags" {
  description = "Pipeline tags value"
  type        = map(string)
  default     = null
}

variable "pipelineawsregion" {
  description = "Pipeline AWS region"
  type        = string
  default     = null
}

variable "pipelineobservability" {
  description = "Enable datadog observarility in all lambdas"
  type        = bool
  default     = false
}

variable "pipelinesuffixversion" {
  description = "Suffix version to add in resources allow like lambda functions. Can be use a commit hash for example"
  type        = string
  default     = ""
}

variable "glue" {
  description = "AWS Glue resources"
  type        = any
  default = {
    connections = {}
  }
}

variable "aws_account_id" {
  description = "AWS account id"
  type        = string
  default     = null
}

variable "pipelinecustomdomainname" {
  description = "Pipeline custom domain name value for apigateway"
  type        = string
  default     = null
}

variable "custom_domain_name" {
  description = "custom domain name value for apigateway"
  type        = string
  default     = null
}

variable "pipelinevpcsecuritygroupids" {
  description = "Pipeline vpc security group id for lambda functions"
  type        = list(string)
  default     = null
}
variable "pipelinevpcsubnetids" {
  description = "Pipeline vpc subnet id for lambda functions"
  type        = list(string)
  default     = null
}

variable "vpc_security_group_ids" {
  description = "Vpc security group id for lambda functions"
  type        = list(string)
  default     = null
}
variable "vpc_subnet_ids" {
  description = "Vpc subnet id for lambda functions"
  type        = list(string)
  default     = null
}
temporaltags = {
  project = "serverless"
  product = "netex"
}

aws_region = "eu-west-1"

project_version = "1.0.0"

lambdas = {
  "authorizer" = {
    source_path     = "../src/auth/"
    function_name   = "authorizer"
    handler         = "app.handler"
    runtime         = "python3.10"
    build_in_docker = true
    # docker_image        = "public.ecr.aws/sam/build-python3.10"
    create_sam_metadata = true
    # store_on_s3         = true
    # s3_bucket           = "netex-serverless-lambda-source"
    # s3_create_bucket    = true
    # s3_prefix           = "authorizer/"
    # timeout             = 300
    # memory_size         = 256
  },
  "responder" = {
    source_path     = "../src/responder/"
    function_name   = "responder"
    handler         = "app.open_handler"
    runtime         = "python3.10"
    build_in_docker = true
    # docker_image        = "public.ecr.aws/sam/build-python3.10"
    create_sam_metadata = true
    publish             = true
    # store_on_s3         = true
    # s3_bucket           = "netex-serverless-lambda-source"
    # s3_prefix           = "responder/"
    # docker_additional_options = [
    #     "-e", "PIP_EXTRA_INDEX_URL=https://!!username!!:!!password!!@nexus.netexlearning.com/repository/bi-python-packages/simple"
    # ]
    # environment_variables = {
    #   "DYNAMODB_TABLE" = "tabletest"
    #   "AWS_SECRET_API_KEY" = "/secrets/common/des/serverless/openapi/key"
    #   "API_KEY" = "value not encrypted with preference to AWS_SECRET_API_KEY"
    # }
    # add_datadog_layer = true
    # layers = [
    #   "arn:aws:lambda:eu-west-1:918667638193:layer:Netex-Extension:1",
    #   "arn:aws:lambda:eu-west-1:918667638193:layer:Netex-Extension:2"
    # ]
    # layers_custom = {
    #   "openai-layer" = {
    #     local_existing_package_path = "../src/layers/openai/openapi.zip"
    #   }
    # }
    # allowed_triggers_custom = {
    #   APIGatewayAny = {
    #     service    = "apigateway"
    #     source_arn = "<arn:apigateway:execution_arn>/*/*" #force AWS APIGateway pre-existing # "${apigateways.apitest.execution_arn}/*/*"
    #   }
    # }
    # allowed_triggers_custom = {
    #   AllowExecutionFromCloudWatch = {
    #     service    = "events"
    #     source_arn = "arn:aws:events:eu-west-1:111122223333:rule/RunDaily"
    #   }
    #   AllowExecutionFromSNS = {
    #     service    = "sns"
    #     source_arn = "arn:aws:sns:eu-west-1:111122223333:any-topic"
    #   }
    # }
    allowed_triggers = {
      apigateway = {
        apitest = {}
      }
      # s3 = {
      #   buckettest = {}
      # }
      # s3 = {
      #   buckettest = {
      #     notifications = [
      #       {
      #         events              = ["s3:ObjectCreated:*"]
      #       },
      #       {
      #         events              = ["s3:ObjectRemoved:*"]
      #         filter_prefix       = "AWSLogs/"
      #         filter_suffix       = ".log"
      #       }
      #     ]
      #   }
      # }
      # sqs = {
      #   queuetest = {}
      #   ## Example with event source mapping configuration      
      #   # queuetest = {
      #   #   event_source_mapping = {
      #   #     batch_size                         = 3
      #   #     maximum_batching_window_in_seconds = 15
      #   #     scaling_config = {
      #   #       maximum_concurrency = 20
      #   #     }
      #   #     filter_criteria = {
      #   #       pattern = "{\"body\":{\"Temperature\":[{\"numeric\":[\">\",0,\"<=\",100]}],\"Location\":[\"Oslo\"]}}"
      #   #     }
      #   #   }
      #   # }
      # }
      # sns = {
      #   topictest = {}
      # }
    }
    # policy_statements_custom = {
    #   AllowDynamoDBCustom = {
    #     effect     = "Allow"
    #     actions    = ["dynamodb:GetItem", "dynamodb:PutItem"]
    #     resources  = ["arn:aws:dynamodb:eu-west-1:111122223333:table/testing"]
    #   }
    # }
    policy_statements = {
      # dynamodb = {
      #   tabletest = {}
      # }
      # s3 = {
      #   buckettest = {}
      # }
      # sqs = {
      #   queuetest = {}
      # }
      # sns = {
      #   topictest = {}
      # }
    }
  }
}

apigateway = {
  name                   = "apitest"
  enable_cloudwatch_role = false
  type                   = "REST" # REST | HTTP | WEBSOCKET
  # endpoint_type = "REGIONAL" # Only for REST apigw type with values: EDGE(default) | REGIONAL
  # custom_domain = false
  # custom_base_path = "custom-base-path" # Route that is concatenated after the custom domain name for apigateway
  resources = {
    "/open" = {
      lambda_name = "responder"
      http_method = ["GET"]
      # timeout_milliseconds = 15000
    },
    "/secure" = {
      lambda_name = "responder"
      http_method = ["GET"]
      # http_method = ["GET","POST"]
      authorizer = true
      # authorizer_id = "<authorizer:id>"  #force authorizer id if you want to use a pre-existing authorizer
    }
    # "wsEndpoint" = {
    #   lambda_name = "sendquery"
    #   response = true
    # }
    # "$connect" = {
    #   lambda_name = "connect"
    # }
    # "$disconnect" = {
    #   lambda_name = "disconnect"
    # }
    # "/event" = { # example of support of integration with SQS, only support with type REST
    #   sqs_name    = "queuetest"
    #   http_method = ["POST"] # only POST method is supported, view https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/integrate-amazon-api-gateway-with-amazon-sqs-to-handle-asynchronous-rest-apis.html
    #   authorizer  = true # if you want to use authorizer, optional configuration
    #   ## If you enabled a lambda authorizer is posible that you want add data in context of the authorizer. To can do this you need customize the request mapping template
    #   ## to add data in message body to send to SQS queue. The following example show pass the property `form` add in lambda authorizer context to the message body:
    #   # request_mapping_template = "Action=SendMessage&MessageBody={\"payload\":$util.urlEncode($input.body),\"authorizerContextPassed\":\"$util.urlEncode($context.authorizer.passed)\"}"
    #   ## More info about how to customize the request mapping template:
    #   ##   https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-mapping-template-reference.html
    #   ##   https://docs.aws.amazon.com/appsync/latest/devguide/utility-helpers-in-util.html
    # }
  },
  # Alternative method for defining API Gateway resources when the same method requires different Lambda functions to be invoked depending on the methods
  # resources = {
  #   "/open" = [
  #     {
  #       lambda_name = "responder"
  #       http_method = ["GET"]
  #     },
  #       lambda_name = "anotherlambda"
  #       http_method = ["POST"]
  #     }
  #   ]
  # }
  authorizer = {
    lambda_name = "authorizer"
    # identity_source = "method.request.header.myheader" # This is a example to set the header "myheader" as identity source. The default value is "method.request.header.Authorization"
    # identity_source = "Example REST: method.request.header.myheader | Example websocket: route.request.header.Auth | Example  HTTP: $request.header.Authorization" 
    # lambda_authorizer_name = "netex-tmp-cloud-authorizer" #[OPTIONAL] parameter to force the name of the centralised lambda authorizer in temporal accounts
  }
}

# dynamodb = {
#   tables = {
#     "tabletest" = {
#       billing_mode = "PROVISIONED"
#       read_capacity = 1
#       write_capacity = 1
#       attributes = [
#         {
#           name = "guid"
#           type = "S"
#         }
#       ]
#       hash_key = "guid"
#       autoscaling = {
#         read = {
#           min_capacity       = 1
#           max_capacity       = 10
#           target_utilization = 70
#         }
#         write = {
#           min_capacity       = 1
#           max_capacity       = 10
#           target_utilization = 70
#         }
#       }
#     }
#   }
# }

# s3 = {
#   buckets = {
#     "buckettest" = {
#       versioning      = true
#       prevent_destroy = true
#       lifecycle_rules = [
#         {
#           filter = {
#             prefix = "tmp/"
#           }
#           expiration = {
#             days = 2
#           }
#         }
#       ]
#       cors_rules = [
#         {
#           allowed_origins = ["*"]
#           allowed_methods = ["GET", "HEAD"]
#           allowed_headers = ["*"]
#           expose_headers  = ["ETag"]
#           max_age_seconds = 3000
#         }
#       ]
#     }
#   }
# }

# sqs = {
#   queues = {
#     "queuetest" = {
#       delay_seconds              = 0
#       max_message_size           = 262144
#       message_retention_seconds  = 172800
#       receive_wait_time_seconds  = 0
#       visibility_timeout_seconds = 10
#       ## The following attributes is event source mapping configuration by default to all lambdas that have this queue as trigger
#       # batch_size                         = 1
#       # maximum_batching_window_in_seconds = 15
#       # scaling_config = {
#       #   maximum_concurrency = 20
#       # }
#       # filter_criteria = {
#       #   pattern = "{\"body\":{\"Temperature\":[{\"numeric\":[\">\",0,\"<=\",100]}],\"Location\":[\"Oslo\"]}}"
#       # }
#     }
#   }
# }

# sns = {
#   topics = {
#     "topictest" = {}
#   }
# }

# glue = {
#   catalog = {
#     databases = {
#       "platform01" = {
#         description = "platform 01 Catalog testing"
#       }
#     }
#     tables = {
#       "glueplatform01" = {
#         catalog_database = "platform01"
#         table_name       = "glueplatform01"
#         description      = "platform 01 table testing"
#         data_format      = "csv"
#         location         = "s3://netex-common-des-common-glue-bucket-c9rl19/output/glue-testing-mysql/tasks/"
#         schema = [
#           {
#             name         = "id"
#             type         = "int"
#           },
#           {
#             name = "title"
#             type = "string"
#           },
#           {
#             name = "start_date"
#             type = "timestamp"
#           },
#           {
#             name = "due_date"
#             type = "timestamp"
#           }
#         ]
#         partition_keys = [
#           {
#             name = "id"
#             type = "int"
#           }
#         ]
#         partition_index = {
#           name = "index_id"
#           keys = ["id"]
#         }
#         serde_parameters = {
#           "separatorChar" = ","
#         }
#       }
#     }
#   }
#   connections = {
#     "glueplatform01" = {
#       jdbc_connection_url    = "local.properties.jdbc_connection_url"
#       subnet_id              = "local.properties.subnet_id"
#       security_group_id_list = "local.properties.security_group_id_list"
#       secret_name            = "local.properties.secret_name"
#     }
#     "glueplatform02" = {
#       jdbc_connection_url    = "jdbc:mysql://<host>:3306/<db>"
#       subnet_id              = "<subnet-id>"
#       security_group_id_list = ["<security-group-id>"]
#       secret_name            = "<secrets-manager-secret-name>"
#     }
#   }
#   jobs = {
#     "glueplatform01" = {
#       script_file_path      = "../src/glue/jobs/glueplatform01/main.py"
#       s3_create_bucket_glue = true
#       connections = [
#         "glueplatform01"
#       ],
#       triggers = {
#         tenant1 = {
#           type     = "SCHEDULED"
#           schedule = "cron(0 0 * * ? *)"
#           arguments = {
#             "--tennat" = "one"
#           }
#         },
#         tenant2 = {
#           type     = "SCHEDULED"
#           schedule = "cron(0 0 * * ? *)"
#           arguments = {
#             "--tennat" = "two"
#           },
#         }
#         trigger3 = {
#           type     = "SCHEDULED"
#           schedule = "cron(0 0 * * ? *)"
#         }
#       }
#     },
#     "glueplatform02" = {
#       script_file_path      = "../src/glue/jobs/glueplatform02/main.py"
#       s3_create_bucket_glue = true
#       connections = [
#         "glueplatform01"
#       ]
#     }
#   }
#   crawlers = {
#     "glueplatform01" = {
#       catalog_database = "platform01"
#       type             = "jdbc"
#       connection       = "glueplatform01"
#       path             = "main/%"
#       job_role         = "glueplatform01"
#       schedule         = "cron(0 0 * * ? *)"
#     }
#   }
# }

# SAM TEMPLATE NETEX SERVERLESS

SAM application template of Netex for simple proyects of AWS Serverless with AWS Lambdas

## Prerequisites

Before you begin, ensure you have met the following minimum requirements:

- **AWS CLI**: Version 2.13 or higher
- **SAM CLI**: Version 1.100.0 or higher
- **Terraform**: Version 1.2.9 or higher

## Installation

Install the required tools following the instructions on their respective official websites:

- [AWS CLI Installation](https://aws.amazon.com/cli/)
- [SAM CLI Installation](https://aws.amazon.com/serverless/sam/)
- [Terraform Installation](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

## Configuring AWS Credentials

To interact with AWS services, you need to set up your AWS credentials. You can configure them in the environment by following these steps:

1. **AWS Access Key and Secret Key**: Obtain your AWS Access Key ID and Secret Access Key from the AWS Management Console under Security Credentials.

2. **Setting up the Credentials**: Run the following commands in your terminal to set up the AWS credentials as environment variables:

   ```bash
   export AWS_ACCESS_KEY_ID='your_access_key_id'
   export AWS_SECRET_ACCESS_KEY='your_secret_access_key'
   export AWS_DEFAULT_REGION='your_default_region'
   ```

   Replace `your_access_key_id`, `your_secret_access_key`, and `your_default_region` with your actual AWS credentials and preferred region.

3. **Verifying the Configuration**: To verify that your credentials are set up correctly, you can run the following command:

   ```bash
   aws sts get-caller-identity
   ```

   This command will return the AWS account information associated with the credentials.

**Note**: In addition to setting environment variables for AWS credentials, you can also configure an AWS profile to use Single Sign-On (SSO). This method is often preferred for its ease of use and enhanced security. [Info about this method.](https://docs.aws.amazon.com/cli/latest/userguide/sso-configure-profile-token.html)

## Getting Started

### Initializing a SAM Application with a Custom Template

To get started with your serverless application using [AWS SAM(Serverless Application Model)](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/sam-specification.html), you can initialize a new SAM project using a custom template from the Netex organization. Here's the command you'll need:

```bash
sam init -n "project-name" --location "https://git.netexlearning.com/exposed/sam-template-netex-serverless.git"
```

Breakdown of the Command:

- `sam init`: This is the command used to initialize a new SAM application.
- `-n "project-name"`: The -n parameter specifies the name of your new SAM application. In this case, the application will be named serverless. You can replace serverless with your preferred project name.
- `--location`: This parameter tells SAM where to find the application template. "https://git.netexlearning.com/exposed/sam-template-netex-serverless.git": This is the URL of the custom SAM application template provided by Netex. This template will be used as the starting point for your application.

Then you can to use the provided bash scripts (`deploy.sh` and `destroy.sh`), you need to be positioned in the `tf-resources` directory. Navigate to this directory using the following command:

```bash
cd ./tf-resources
```

### Preriquesites to use deploy.sh and destroy.sh scripts

To use the provided bash scripts (`deploy.sh` and `destroy.sh`), you need to have the following prerequisites:

- Project with git repository initialized with name ended in `-terrasam-state` (e.g. `project-name-terrasam-state`). [See this documentation.](https://wiki.netexlearning.com/display/NA/Serverless)
- Setted the correct credential to access to AWS account temporal to deploy the resources. See the seccion [Configuring AWS Credentials](#configuring-aws-credentials).

This allow work with the terraform state in a remote backend, and the scripts will take care of the necessary configurations. The use of terraform state in a remote backend is a best practice to avoid conflicts when working in a team in same project and AWS account.
This terraform backend is configured to save the state in a S3 bucket with prefix `netex-tf-state` and a subfolder with the name of the project. This bucket is created in AWS account temporal to deploy the resources.
Also is configured the locking of the state with DynamoDB table with prefix `netex-tf-state`. This block the terraform changes of resources if another user is working in the same project in the same time.

### Deploying Resources

To create all the required resources, run the `deploy.sh` script:

```bash
./deploy.sh
```

This script will execute the necessary commands to set up your environment according to the defined infrastructure as code (IaC) configurations.

This bash support the following optional parameters:

- `--dryrun`: not run the terraform apply command, only prepare the terraform backend requirements.
- `--skip`: skip the upgrade of the terraform modules and the terraform init command.

### Destroying Resources

To clear all the resources that were created by the `deploy.sh` script, use the `destroy.sh` script:

```bash
./destroy.sh
```

This script will tear down all the resources, ensuring that no unnecessary costs are incurred.

## Additional Information

Make sure you have the necessary permissions and configurations set up in your AWS environment to run these scripts successfully.

### Minimal Permissions Required

To successfully deploy and manage the resources with the provided scripts, the following AWS IAM policy outlines the minimal permissions required. This policy is a baseline configuration and does not include permissions for additional AWS services like S3, SQS, and SNS, which you might need depending on your specific use case.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:CreatePolicy",
        "iam:CreatePolicyVersion",
        "iam:TagRole",
        "iam:TagPolicy",
        "iam:GetRole",
        "iam:GetPolicy",
        "iam:ListRolePolicies",
        "iam:GetPolicyVersion",
        "iam:ListAttachedRolePolicies",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:ListPolicyVersions",
        "iam:ListInstanceProfilesForRole",
        "iam:DeletePolicy",
        "iam:DeletePolicyVersion",
        "iam:DeleteRole",
        "iam:PutRolePolicy",
        "iam:GetRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:CreateServiceLinkedRole",
        "application-autoscaling:RegisterScalableTarget",
        "application-autoscaling:TagResource",
        "application-autoscaling:DescribeScalableTargets",
        "application-autoscaling:ListTagsForResource",
        "application-autoscaling:PutScalingPolicy",
        "application-autoscaling:DescribeScalingPolicies",
        "application-autoscaling:DeleteScalingPolicy",
        "application-autoscaling:DeregisterScalableTarget",
        "logs:*",
        "apigateway:*",
        "dynamodb:*",
        "lambda:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["iam:PassRole"],
      "Resource": "arn:aws:iam::*:role/*"
    }
  ]
}
```

### Lambda source code build and save in S3 bucket

We see the following setup in lambda definition tfvars:

```
store_on_s3         = true
s3_bucket           = "netex-serverless-lambda-source"
s3_create_bucket    = true
s3_prefix           = "serverless/"
```

- With `store_on_s3`, we indicate that we will store the code package in an S3 bucket and it should use that for deployment. This is a mandatory boolean if this support is used.
- With `s3_bucket`, we specify the name of the S3 bucket to be created to store the lambda code, it must be unique and will fail if someone already has that same bucket name in use.
- With `s3_create_bucket`, the framework itself takes care of creating the bucket, naming it as indicated in `s3_bucket`, and if this is not defined, it will assign a standard name (`netex-%tag[project]-%tag[env]-%tag[product]-lambda-source-%ramdomID`) with a random suffix.
- With `s3_prefix`, you indicate a prefix to the S3 objects, this way

### Use of AWS Secret Manager or Parameter Store in Lambda functions

We recomend to use the integrate AWS Lambda functions with AWS Secrets Manager and AWS Systems Manager Parameter Store to leveraging these services, you can securely store and manage sensitive information such as database passwords, API keys, and other secrets.

#### - AWS Secrets Manager

AWS Secrets Manager helps you protect access to your applications, services, and IT resources without the upfront cost and complexity of maintaining a secure infrastructure. The service enables you to easily rotate, manage, and retrieve secrets throughout their lifecycle.

For integrating AWS Secrets Manager with Lambda, refer to the official AWS documentation: [Retrieving Secrets Stored in AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/retrieving-secrets_lambda.html).

#### - AWS Systems Manager Parameter Store

AWS Systems Manager Parameter Store provides secure, hierarchical storage for configuration data and secrets. You can store data such as passwords, database strings, and license codes as parameter values.

For integrating AWS Systems Manager Parameter Store with Lambda, refer to the official AWS documentation: [Integrating AWS Systems Manager Parameter Store with AWS Lambda](https://docs.aws.amazon.com/systems-manager/latest/userguide/ps-integration-lambda-extensions.html).

#### - Environment Variables Prefix: `AWS_SECRET_`

To utilize this functionality, your Lambda function environment variables should be defined with the prefix `AWS_SECRET_`. These environment variables should contain the name of the AWS Secret or Parameter Store value they reference.

For example, if you have a secret in AWS Secrets Manager or Parameter Store named `/secrets/project/env/serverless/openapi/key`, you would set an environment variable in your Lambda function like this:

- Name: `AWS_SECRET_MY_ENV_VAR_NAME`
- Value: The name of the secret in AWS Secrets Manager, e.g., `/secrets/project/env/serverless/openapi/key`

When your Lambda function runs, it will use the names provided in these environment variables to retrieve the corresponding secrets from AWS Secrets Manager or Parameter Store.

To retrieve the value, we recommend using code similar to this in Python, which is capable of fetching the secret's value from the service:

```
import requests

def get_aws_secret(env_var_name):
    aws_secret_varsecret = os.environ.get(env_var_name)
    headers = {"X-Aws-Parameters-Secrets-Token": os.environ.get('AWS_SESSION_TOKEN')}

    if aws_secret_varsecret is not None:
        # Get Secret form AWS Systems Manager Parameter Store
        try:
            secrets_extension_endpoint = "http://localhost:2773/systemsmanager/parameters/get?withDecryption=true&name=" + aws_secret_varsecret
            r = requests.get(secrets_extension_endpoint, headers=headers)
            return json.loads(r.text)["Parameter"]["Value"]
        except requests.RequestException as e:
            # Send some context about this error to Lambda Logs with the secret extension endpoint
            print(e)

        # Get Secret form AWS Secrets Manager if not found in Parameter Store
        try:
            secrets_extension_endpoint = "http://localhost:2773/secretsmanager/get?secretId=" + aws_secret_varsecret
            r = requests.get(secrets_extension_endpoint, headers=headers)
            return json.loads(r.text)["SecretString"]
        except requests.RequestException as e:
            # Send some context about this error to Lambda Logs with the secret extension endpoint
            print(e)

    return None

api_key = os.environ.get('API_KEY')
if api_key is None:
    api_key = get_aws_secret('AWS_SECRET_API_KEY')
```

This Python code defines a function `get_aws_secret(env_var_name)` that is used to retrieve secret values from AWS services integrated with AWS Lambda functions. The function attempts to fetch secret values either from AWS Systems Manager Parameter Store or AWS Secrets Manager, depending on where the secret is stored.

Here's a breakdown of what the code does:

1. **Function Definition**: The function `get_aws_secret(env_var_name)` takes an environment variable name as its input.

2. **Check for Environment Variable**: The function first checks if the provided environment variable (like `AWS_SECRET_API_KEY`) exists. If it does, it proceeds to retrieve the secret value associated with it.

3. **Fetch from Parameter Store**:

   - It constructs a URL to access the AWS Systems Manager Parameter Store using a local endpoint.
   - It sends a GET request to this endpoint to retrieve the secret value.
   - If the request is successful, the function returns the value of the secret.
   - If there's an exception, it prints the error to Lambda logs.

4. **Fetch from Secrets Manager**:

   - If the secret is not found in the Parameter Store, it constructs a URL for the AWS Secrets Manager.
   - It then makes a GET request to this URL.
   - If the request is successful, the function returns the secret string.
   - If there's an exception, it prints the error to Lambda logs.

5. **Using the Function**:
   - The code checks if the `API_KEY` environment variable is set.
   - If `API_KEY` is not set, it calls `get_aws_secret('AWS_SECRET_API_KEY')` to fetch the API key from the AWS secrets services.
   - This allows the Lambda function to dynamically use an API key either from a predefined environment variable or from AWS's secret management services.

This approach ensures that the Lambda function can securely access sensitive information like API keys without hardcoding them, adhering to best practices for secret management.

Remember to include the required library requests in your Lambda function's deployment package. You can do this by adding the following line to your `requirements.txt` file:

```
requests>=2.27.0
```

### DEFINITION OF ENVIROMENT VARIABLES IN LAMBDA FUNCTIONS FOR DIFFERENT ENVIRONMENTS

For the definition of environment variables in lambda functions for different environments, we can use the diferents environments files in src path of each lambda function. The `<environment_name>.env` files are used to define environment variables for different environments (e.g. des, pre, pro).

In the actuality, we have the folowing environments:

- `des`: Development environment AWS account where the file is named `des.env`
- `pre`: Pre-production environment AWS account where the file is named `pre.env`
- `pro`: Production environment AWS account where the file is named `pro.env`

In addition we have the tmp environment for testing purposes in AWS temporary accounts, where the file is named `tmp.env`

The flow src tree sample is as follows:

```
.
├── src
│   ├── responder
│       ├── des.env   # => Terrasam use this file in deploy pipeline of DES environment
│       ├── pre.env   # => Terrasam use this file in deploy pipeline of PRO environment
│       ├── pro.env   # => Terrasam use this file in deploy pipeline of PRO environment
│       ├── tmp.env   # => Terrasam use this file because the tag environment is "tmp", for testing purposes
│       ├── app.py
│       └── requirements.txt
```

In adition to this support the values defined in property `environment_variables` of lambda definition in `terraform.tfvars` file, will be merged with the values defined in the environment file, giving priority to the values defined in the environment file.

### DEFINITION OF PROPERTIES TO USE IN TERRAFORM VARS REFERENCE

:exclamation: Actually only support in glue resources.

To define properties to use in tfvars file with diferents values for each environment, can use be defined in yaml file in path `properties/<environment_name>.yaml` where `<environment_name>` is the name of the environment.
For example to environments `tmp`, `des`, `pre` and `pro` the structure is as follows:

```
.
├── properties
│   ├── global.yaml
│   ├── tmp.yaml
│   ├── des.yaml
│   ├── pre.yaml
│   └── pro.yaml
```

And the format of this yaml fiels is as follows:

```yaml
properties:
  job1_script_location: "s3://bucket-name/path/to/script.py"
  job1_role_arn: "arn:aws:iam::account-id:role/role-name"
  capacity: 2
  max_concurrent_runs: 1
  ssl_mode: true
  array_value:
    - "one"
    - "two"
  map_value:
    property1: "one"
    property2: "two"
```

The `global.yaml` file is used to define properties that are common to all environments, and the properties defined in the environment files will override the values defined in the global file.

In the terraform vars file, the properties can be used as follows:

```hcl
...
   connections = {
     "glueplatform01" = {
       jdbc_connection_url    = "local.properties.jdbc_connection_url"
       subnet_id              = "local.properties.subnet_id"
       security_group_id_list = "local.properties.security_group_id_list"
       secret_name            = "local.properties.secret_name"
     }
   }
...
```

All values with string that start by `local.properties.` will be replaced by the value defined in the properties file.

### Custom Domains for apigateway

When the `custom_domain` variable is enabled, a custom domain can be generated in the API Gateway. This will create a URL in the following format:
`https://api-service.des.learningcloud.me/<product>-<project>-<apigateway_name>/`

If the `custom_base_path` variable is also enabled, a URL with the specified base path will be generated in this format:
`https://api-service.des.learningcloud.me/<custom_base_path>/`

Both URLs will be displayed in the pipeline through the value of `custom_url`.

### DEFINITION OF ARGUMENTS TO USE IN GLUE JOBS TRIGERS

To define arguments to use in glue jobs triggers with diferents values for each environment can be defined the files `arguments.yaml` in the same path of scripts files.

For example to environments `tmp`, `des`, `pre` and `pro` the structure is as follows:

```
.
├── src
│   ├── glue
│       ├── job1
│       │   ├── jobscript.py
│       │   └── arguments.yaml
│       └── job2
│           └──jobscript.py
```

And the format of this yaml fiels is as follows:

```yaml
tmp:
  "--env": "tmp"
  "--arg_tmp_1": "debug"
des:
  "--mode": "initial"
  "--size": 9878
pre:
  "--mode": "raw"
  "--size": 0
pro:
  "--mode": "raw"
  "--size": 0
```

Atention: All arguments keys should start with `--` so is recomendant set this keys in string format.

This feature is used to define arguments to use in glue jobs triggers, and the values defined in the environment file will be added to the arguments defined in the `terraform.tfvars` file. If the same argument is defined in both files, the value defined in the environment file will override the value defined in the `terraform.tfvars` file.

### AWS LAMBDA AUTHORIZER CENTRALIZED

The centralized authorizer is a lambda function that is used to authorize requests to multiple APIs. This function is used to validate the JWT token and authorize the request. If we want to use the centralized authorizer lambda available in the environment, we need to set the following configuration.

The centralized authorizer is defined in the `terraform.tfvars` file with the `authorizer` property in resources of api gateway.

```hcl
...
apigateway = {
  name                   = "apitest"
  type                   = "REST"
  resources = {
    "/secure" = {
      lambda_name = "responder"
      http_method = ["GET"]
      authorizer = true
    }
  }
}
```

Also we can configure some properties of the AWS ApiGateway Authorizer in the `terraform.tfvars` file with the `authorizer` property in apigateway like the following example:

```hcl
...
apigateway = {
  name                   = "apitest"
  type                   = "REST"
  resources = {
    "/secure" = {
      lambda_name = "responder"
      http_method = ["GET"]
      authorizer = true
    }
  }
  authorizer = {
    identity_source = "method.request.header.jwtcustomheader"
    authorizer_result_ttl_in_seconds = 300
    dentity_validation_expression = ""
  }
}
```

The AWS Lambda centralized authorizer is not available for AWS temporary accounts. Therefore, if you want to use one that is available, the following configuration can be used:

```hcl
...
apigateway = {
  name                   = "apitest"
  type                   = "REST"
  resources = {
    "/secure" = {
      lambda_name = "responder"
      http_method = ["GET"]
      authorizer = true
    }
  }
  authorizer = {
    lambda_authorizer_name = "netex-cloud-authorizer"
  }
}
```

In this case the `lambda_authorizer_name` property is used to define the name of the AWS Lambda function that will be used as the centralized authorizer in a temporary account.

### MAC OSX with ARM architecture

If you are using a MAC with an ARM architecture(M1, M2 or M3), you may encounter issues when running the `deploy.sh` script. This is because the docker build of lambda package is not fully compatible with ARM architecture yet. Really the problem is some of the dependencies used in the lambda package are not compatible with ARM architecture.

To work around this issue, you can set the platform to `linux/amd64` in the docker_additional_options of terraform.tfvars of any lambda function. This will force the docker build to use the x86_64 architecture, which is compatible with ARM architecture.

```bash
...
    docker_additional_options = [
        ...
        "--platform", "linux/amd64",
        ...
    ]
...
```

### Windows Compatibility Issue

**Important Notice for Windows Users**: We currently have an [open issue](https://github.com/terraform-aws-modules/terraform-aws-lambda/issues/142) regarding compatibility with the Windows environment for [aws lambda module](https://github.com/terraform-aws-modules/terraform-aws-lambda). Efforts are underway to resolve this, but Windows users may experience difficulties in the meantime.

To work around this issue, Windows users are advised to:

- Use a **Virtual Machine (VM)** with a Linux distribution. This provides a complete Linux environment, ensuring compatibility.
- Alternatively, consider using **Windows Subsystem for Linux (WSL)**. WSL allows you to run a Linux environment directly on Windows, without the overhead of a traditional VM.
- Building packages **without Docker** setting in `terraform.tfvars` file the `build_in_docker` variable to `false`. For this option ensure that your local environment matches the required engine version (e.g., Node.js, Python) as specified in your project. This is crucial for compatibility and successful deployment.

### AWS Lambda function limitations

AWS Lambda functions have certain limitations that you should be aware of when designing your serverless applications. Some of the key limitations include:

- **Execution Time**: Lambda functions have a maximum execution time of 15 minutes. If your function runs for longer than this, it will be automatically terminated.
- **Memory Limit**: Lambda functions have a memory limit that ranges from 128 MB to 10 GB, depending on the configuration. If your function exceeds this limit, it will be terminated.
- **Disk Space**: Lambda functions have a limited amount of disk space available for temporary storage. If your function requires more disk space, you may need to use an external storage service like Amazon S3.
- **Environment Variables**: Lambda functions have a limit on the number of environment variables that can be set. If you exceed this limit, you may need to find an alternative way to store configuration data.
- **Concurrent Executions**: Lambda functions have a limit on the number of concurrent executions that can be run at the same time. If you exceed this limit, your function may be throttled.
- **Cold Start**: Lambda functions have a cold start time, which is the time it takes to initialize the function the first time it is run. If your function has a long cold start time, you may need to optimize it to reduce latency.
- **Dependencies**: Lambda functions have a limit on the size of dependencies that can be included in the deployment package. If your function exceeds this limit, you may need to find an alternative way to manage dependencies. This limit is 250 MB (unzipped) as sum of all layers and the function code. As default the lambda functions deployed in environments DES, PRE and PRO include three layers: two datadog layers and one layer to work with AWS Secrets Manager and AWS Systems Manager Parameter Store, this default three layers have a size of 41.5 MB (unzipped) approximately. So the size of the function code and dependencies should not exceed 208 MB (unzipped) approximately.

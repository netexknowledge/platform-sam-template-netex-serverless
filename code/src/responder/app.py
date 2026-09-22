import json
import requests
import os

# Get Secret form AWS Systems Manager Parameter Store or AWS Secrets Manager
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


def open_handler(event, context):

    api_key = os.environ.get('API_KEY')
    if api_key is None:
        api_key = get_aws_secret('AWS_SECRET_API_KEY')

    try:
        ip = requests.get("http://checkip.amazonaws.com/")
    except requests.RequestException as e:
        # Send some context about this error to Lambda Logs
        print(e)

        raise e

    # Debug print:
    # print event to CloudWatch Logs
    print(event)
    # print context to CloudWatch Logs
    print(context)

    api_id = event.get("requestContext", {}).get("apiId")
    proto = event.get("headers", {}).get("X-Forwarded-Proto")
    host = event.get("headers", {}).get("Host")
    stage = event.get("requestContext", {}).get("stage")
    resource_path = event.get("requestContext", {}).get("resourcePath")
    apigateway_path = None
    if proto is not None and host is not None and stage is not None and resource_path is not None:
        apigateway_path = proto + "://" + host + "/" + stage + resource_path

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Hello TF World",
            "location": ip.text.replace("\n", ""),
            "secret": api_key,
            "apigateway_id": api_id,
            "apigateway_path": apigateway_path
        }),
    }

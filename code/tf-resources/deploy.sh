#!/bin/bash
export AWS_PAGER=""

set -e

create_s3bucket_tfstate() {
  bucket_name=$1

  # create the bucket s3 to store the terraform state if not exists
  if ! aws s3api head-bucket --bucket "$bucket_name" > /dev/null 2>/dev/null; then
    aws s3api create-bucket --bucket "$bucket_name" --region "eu-west-1" --create-bucket-configuration LocationConstraint=eu-west-1 > /dev/null
    # make the bucket private
    aws s3api put-public-access-block --bucket "$bucket_name" --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" > /dev/null
    # add a tag
    aws s3api put-bucket-tagging --bucket "$bucket_name" --tagging '{"TagSet": [{"Key": "tool", "Value": "terrasam"}]}' > /dev/null
    echo "Bucket $bucket_name created."
  fi
}

create_dynamodb_tftable() {
  table_name=$1
  account_id=$2

  # create the dynamodb table to store the terraform state lock if not exists
  if ! aws dynamodb describe-table --table-name "$table_name" --region "eu-west-1" > /dev/null 2>/dev/null; then
    aws dynamodb create-table --table-name "$table_name" --region "eu-west-1" --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 --tags "Key=tool,Value=terrasam" > /dev/null
    echo "Dynamodb table $table_name created."
  fi
}

create_main_tf() {
  remote_repository=$1
  account_id=$2

  bucket_name="netex-tf-state-$account_id"
  table_name="netex-tf-state-$account_id"

  create_s3bucket_tfstate "$bucket_name"
  create_dynamodb_tftable "$table_name" "$account_id"

  echo "terraform {" > "main.tf"
  echo "  backend \"s3\" {" >> "main.tf"
  echo "    bucket = \"$bucket_name\"" >> "main.tf"
  echo "    key = \"$remote_repository/terraform.tfstate\"" >> "main.tf"
  echo "    region = \"eu-west-1\"" >> "main.tf"
  echo "    dynamodb_table = \"$table_name\"" >> "main.tf"
  echo "  }" >> "main.tf"
  echo "}" >> "main.tf"
  echo " " >> "main.tf"
  echo "provider \"aws\" {" >> "main.tf"
  echo "  region = local.aws_region" >> "main.tf"
  echo "}" >> "main.tf"
  echo " " >> "main.tf"
}

#check if aws cli is installed
if ! [ -x "$(command -v aws)" ]; then
  echo 'Error: aws cli is not installed.' >&2
  exit 1
fi

#check if terraform is installed
if ! [ -x "$(command -v terraform)" ]; then
  echo 'Error: terraform is not installed.' >&2
  exit 1
fi

# Check if this a git project and get the remote repository name in remote_repository var
remote_repository=""
script_dir=$(dirname "$0")
if [ -d "$script_dir/../.git" ]; then
  remote_repository=$(git -C "$script_dir/../" remote -v | awk '{print $2}' | head -n1 | awk -F'/' '{sub(/\.git$/, "", $NF); print $NF}')
  if [[ $remote_repository != *"-terrasam-state" ]]; then
    echo "Remote repository does not end with -terrasam-state. Exiting..."
    exit 1
  fi
else
  echo "This is not a git project. Is required to be a git project with remote repository to deploy the resources. Exiting..."
  exit 1
fi

# Check if current dir is tf-resources with pwd comand
if [ "${PWD##*/}" != "tf-resources" ]; then
  echo "This script must be executed from the tf-resources directory. Exiting..."
  exit 1
fi

# Get the account id and exit if it fails
account_id=$(aws sts get-caller-identity --query Account --output text)
if [ $? -ne 0 ]; then
  echo "Failed to get the account id. Check that you have config the env variables of aws credentials. Exiting..."
  exit 1
fi

# Check if terraform have a backend config
if [ -f "main.tf" ]; then
  backend_configured=$(grep -c "backend \"s3\"" "main.tf" || true)
  backend_commented=$(grep -c "^[[:space:]]*#.*backend \"s3\"" "main.tf" || true)
  if [ $backend_configured -eq 0 ] || [ $backend_commented -gt 0 ]; then
    create_main_tf "$remote_repository" "$account_id"
  else
    echo "The backend is already configured."
  fi
else
  create_main_tf "$remote_repository" "$account_id"
fi

unset AWS_PAGER

# check if first param if --dryrun then exit
if [ "$1" == "--dryrun" ]; then
  echo "Dry run executed. Exiting..."
  exit 0
fi

# clear previous builds
rm -rf builds

# check if first param is --skip then terraform init without upgrade
if [ "$1" == "--skip" ]; then
  terraform init
else
  terraform init --upgrade
fi

terraform apply -auto-approve

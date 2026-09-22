#!/bin/bash

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

# be careful with this command, it will destroy all resources
echo "This will destory all resources created by terraform. Can you confirm? (y/n)"
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    echo "Destroying resources..."
else
    echo "Exiting..."
    exit 1
fi

terraform destroy -auto-approve

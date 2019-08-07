#!/bin/sh
set -e
cat << EOF > terraform.tf
terraform {
  required_version = ">= ${1?usage: $0 <version>}"
}
EOF

# Required providers.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.52.0"
    }
  }
}

# AWS provider settings.
provider "aws" {
  access_key                  = var.access_key
  secret_key                  = var.secret_key
  region                      = var.region
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Customize API endpoints.
  endpoints {
    s3       = "http://s3.${var.endpoint}"
    iam      = "http://${var.endpoint}"
    lambda   = "http://${var.endpoint}"
    dynamodb = "http://${var.endpoint}"
  }
}


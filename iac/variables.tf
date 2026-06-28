# Default environment.
variable "environment" {
  type    = string
  default = "localstack"
}

# Default region.
variable "region" {
  type    = string
  default = "us-east-1"
}

# Default access key.
variable "access_key" {
  type    = string
  default = "localstack"
}

# Default secret key.
variable "secret_key" {
  type    = string
  default = "localstack"
}

# Default API endpoint.
variable "endpoint" {
  type    = string
  default = "localhost.localstack.cloud:4566"
}
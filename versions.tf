terraform {
  required_version = ">= 1.15.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.51"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

terraform {
    required_version = "~> 0.14"
    required_providers {
        aws = {
            source = "hashicorp/aws"
            #  Lock version to avoid unexpected problems
            version = "3.46"
        }
    }
}

provider "aws" {
  region = "us-east-1"
}
provider "namecheap" {}

provider "aws" {
  region  = "us-east-1"
  profile = "pjaudiomv"
}

terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2"
    }
    namecheap = {
      source  = "namecheap/namecheap"
      version = ">= 2.0.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0.0"
    }
  }

  backend "s3" {
    bucket         = "tomato-terraform-state-patrick"
    key            = "state/congrats-jessie.tfstate"
    dynamodb_table = "tomato-terraform-state-patrick"
    region         = "us-east-1"
    profile        = "pjaudiomv"
  }
}


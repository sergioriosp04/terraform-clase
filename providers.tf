terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket       = "itm-seminario-lab-2"
    key          = "tfstate/terraform.tfstate"
    use_lockfile = true
    region       = "us-east-1"
    encrypt      = true
    profile      = "seminario"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
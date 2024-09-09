terraform {
  backend "s3" {
    bucket         = "fgtf-infra"
    key            = "ecr.tfstate"
    region         = "us-east-1"
    //dynamodb_table = "terraform_lock"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}


provider "aws" {
  region  = "us-east-1"
  profile = "default"
}



resource "aws_ecr_repository" "fgms-web" {
  name = "fgms-web"
}

resource "aws_ecr_repository" "fgms-php" {
  name = "fgms-php"
}

resource "aws_ecr_repository" "fgms-db" {
  name = "fgms-db"
}

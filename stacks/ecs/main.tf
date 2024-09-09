terraform {
  backend "s3" {
    bucket         = "fgtf-infra"
    key            = "ecs.tfstate"
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


resource "aws_ecs_cluster" "fgms_ecs_cluster" {
  name = "fgms_ecs_cluster"
}

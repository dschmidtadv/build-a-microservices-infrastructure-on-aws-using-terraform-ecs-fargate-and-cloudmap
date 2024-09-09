terraform {
  backend "s3" {
    bucket         = "fgtf-infra"
    key            = "dns.tfstate"
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



data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "fgtf-infra"
    key    = "vpc.tfstate"
    region = "us-east-1"
  }
}


resource "aws_service_discovery_private_dns_namespace" "fgms_dns_discovery" {
  name        = var.fgms_private_dns_namespace
  description = "fgms dns discovery"
  vpc         = data.terraform_remote_state.vpc.outputs.fgms_vpc_id
}

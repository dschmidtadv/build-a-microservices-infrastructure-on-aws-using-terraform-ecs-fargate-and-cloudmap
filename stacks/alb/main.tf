terraform {
  backend "s3" {
    bucket         = "fgtf-infra"
    key            = "alb.tfstate"
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


resource "aws_lb" "fgms_alb" {
  load_balancer_type = "application"
  subnets            = data.terraform_remote_state.vpc.outputs.fgms_public_subnets_ids
  security_groups    = ["${aws_security_group.fgms_alb_sg.id}"]
}

resource "aws_security_group" "fgms_alb_sg" {
  description = "controls access to the ALB"
  vpc_id      = data.terraform_remote_state.vpc.outputs.fgms_vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

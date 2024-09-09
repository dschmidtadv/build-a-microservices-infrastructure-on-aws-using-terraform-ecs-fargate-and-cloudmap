terraform {
  backend "s3" {
    bucket         = "fgtf-infra"
    key            = "services-php.tfstate"
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

data "terraform_remote_state" "dns" {
  backend = "s3"
  config = {
    bucket = "fgtf-infra"
    key    = "dns.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "alb" {
  backend = "s3"
  config = {
    bucket = "fgtf-infra"
    key    = "alb.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "ecs_cluster" {
  backend = "s3"
  config = {
    bucket = "fgtf-infra"
    key    = "ecs.tfstate"
    region = "us-east-1"
  }
}
resource "aws_cloudwatch_log_group" "fgms_log_group" {
  name = "/ecs/fgms_log_group_php"

}


resource "aws_iam_policy" "fgms_php_task_role_policy" {
  name        = "fgms_php_task_role_policy"
  description = "fgms php task role policy"

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Effect : "Allow",
          Action : [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource : "*"
        }
      ]
    }
  )
}


resource "aws_iam_role" "fgms_php_task_role" {
  name = "fgms_php_task_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Effect : "Allow",
          Principal : {
            Service : "ecs-tasks.amazonaws.com"
          },
          Action : [
            "sts:AssumeRole"
          ]
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.fgms_php_task_role.name
  policy_arn = aws_iam_policy.fgms_php_task_role_policy.arn
}


resource "aws_ecs_task_definition" "fgms_php_td" {
  family                   = "fgms_php_td"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.fgms_php_task_role.arn

  container_definitions = jsonencode(
    [
      {
        cpu : 256,
        image : "211125583596.dkr.ecr.us-east-1.amazonaws.com/fgms-php:v1",
        memory : 512,
        name : "fgms-php",
        networkMode : "awsvpc",
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.fgms_log_group.name
            awslogs-region        = "us-east-1"
            awslogs-stream-prefix = "nginx"
          }
        },
        portMappings : [
          {
            containerPort : 3000,
            hostPort : 3000
          }
        ]
      }
    ]
  )
}

resource "aws_ecs_service" "fgms_php_td_service" {
  name            = "fgms_php_td_service"
  cluster         = data.terraform_remote_state.ecs_cluster.outputs.fgms_ecs_cluster_id
  task_definition = aws_ecs_task_definition.fgms_php_td.arn
  desired_count   = "1"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${aws_security_group.ecs_tasks_sg_php.id}"]
    subnets         = ["${data.terraform_remote_state.vpc.outputs.fgms_private_subnets_ids[0]}"]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.fgms_php_service.arn
  }
}

resource "aws_security_group" "ecs_tasks_sg_php" {
  name        = "ecs_tasks_sg_php"
  description = "allow inbound access from the ALB only"
  vpc_id      = data.terraform_remote_state.vpc.outputs.fgms_vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = "3000"
    to_port     = "3000"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_service_discovery_service" "fgms_php_service" {
  name = var.fgms_php_service_namespace

  dns_config {
    namespace_id = data.terraform_remote_state.dns.outputs.fgms_dns_discovery_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 2
  }
}

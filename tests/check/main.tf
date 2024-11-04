terraform {
  required_version = ">= 1.8.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}

variable "repo_name" {
  type = string
}
variable "image_tag" {
  type = string
}

data "aws_ecr_image" "service_image" {
  repository_name = var.repo_name
  image_tag       = var.image_tag
}

output "pushed_at" {
  value = data.aws_ecr_image.service_image.image_pushed_at
}

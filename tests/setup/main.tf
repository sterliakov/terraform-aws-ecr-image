terraform {
  required_version = ">= 1.8.2"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
}

resource "random_pet" "repo_suffix" {
  length = 8
}

resource "aws_ecr_repository" "test" {
  name         = "ecr-test-${random_pet.repo_suffix.id}"
  force_delete = true
}

output "repo_name" {
  value = aws_ecr_repository.test.name
}
output "repo_url" {
  value = aws_ecr_repository.test.repository_url
}

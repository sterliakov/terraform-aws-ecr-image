terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.40.0"
      configuration_aliases = [aws.main, aws.virginia]
    }
  }
}

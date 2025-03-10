resource "aws_ecr_repository" "example" {
  name         = "example"
  force_delete = true
}

module "ecr_repo_image" {
  source  = "sterliakov/ecr-image/aws"
  version = "0.2.0"
  providers = {
    aws.main     = aws
    aws.virginia = aws
  }

  push_ecr_is_public = false
  push_repo_fqdn     = replace(aws_ecr_repository.example.repository_url, "//.*$/", "") # remove everything after first slash
  push_repo_name     = aws_ecr_repository.example.name
  push_image_tag     = local.deployed_tag
}

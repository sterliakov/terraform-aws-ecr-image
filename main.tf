data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}
data "aws_ecr_authorization_token" "token" {
  provider = aws.main
}

locals {
  pull_then_push_path = "${path.module}/scripts/pull_then_push.sh"
  download_prefix     = uuid()
  download_dir_path   = "${path.root}/.terraform/tmp/${local.download_prefix}-image"

  pull_token = (
    var.pull_ecr_is_public
    ? "Bearer ${data.aws_ecrpublic_authorization_token.token.authorization_token}"
    : "Basic ${data.aws_ecr_authorization_token.token.authorization_token}"
  )
  push_token = (
    var.push_ecr_is_public
    ? "Bearer ${data.aws_ecrpublic_authorization_token.token.authorization_token}"
    : "Basic ${data.aws_ecr_authorization_token.token.authorization_token}"
  )
}

resource "terraform_data" "ecr_repo_image" {
  triggers_replace = [
    var.pull_image_tag,
    var.pull_image_arch,
    var.pull_repo_name,
    var.pull_repo_fqdn,

    var.push_image_tag,
    var.push_repo_name,
    var.push_repo_fqdn,
  ]

  provisioner "local-exec" {
    command     = local.pull_then_push_path
    interpreter = ["bash", "-c"]
    environment = {
      PULL_CURL_AUTH_HEADER  = local.pull_token
      PULL_REPO_FQDN         = var.pull_repo_fqdn
      PULL_REPO_NAME         = var.pull_repo_name
      PULL_IMAGE_TAG         = var.pull_image_tag
      PULL_IMAGE_ARCH        = var.pull_image_arch
      PULL_DOWNLOAD_DIR_PATH = local.download_dir_path
      PUSH_CURL_AUTH_HEADER  = local.push_token
      PUSH_REPO_FQDN         = var.push_repo_fqdn
      PUSH_REPO_NAME         = var.push_repo_name
      PUSH_IMAGE_TAG         = var.push_image_tag
    }
  }
}

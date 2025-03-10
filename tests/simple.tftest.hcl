provider "aws" {
  region = "us-east-1"
}

variables {
  tag = "deployed"
}

run "setup" {
  module {
    source = "./tests/setup"
  }
}

run "execute" {
  providers = {
    aws.main = aws
    aws.virginia = aws
  }

  variables {
    push_repo_fqdn     = replace(run.setup.repo_url, "//.*$/", "") # remove everything after first slash
    push_repo_name     = run.setup.repo_name
    push_image_tag     = var.tag
  }
}

run "verify" {
  module {
    source = "./tests/check"
  }
  variables {
    repo_name     = run.setup.repo_name
    image_tag = var.tag
  }
}

run "execute_again" {
  # Ensure no drift
  variables {
    push_repo_fqdn     = replace(run.setup.repo_url, "//.*$/", "") # remove everything after first slash
    push_repo_name     = run.setup.repo_name
    push_image_tag     = var.tag
  }
}

run "verify_again" {
  module {
    source = "./tests/check"
  }
  variables {
    repo_name     = run.setup.repo_name
    image_tag = var.tag
  }

  assert {
    condition = data.aws_ecr_image.service_image.image_pushed_at == run.verify.pushed_at
    error_message = "Image was replaced unexpectedly."
  }
}

module "github_actions_test_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.47.1"

  name     = "ecr-test-role"
  subjects = ["${local.repo}:*"]
  policies = {
    extra = aws_iam_policy.github_actions_test.arn
  }
}

resource "aws_iam_policy" "github_actions_test" {
  name   = "update-backend-lambda"
  policy = data.aws_iam_policy_document.github_actions_test.json
}

data "aws_iam_policy_document" "github_actions_test" {
  statement {
    actions   = ["ecr:*"]
    resources = ["arn:aws:ecr:*:*:repository/ecr-test-*"]
  }
  statement {
    #checkov:skip=CKV_AWS_107:Token is needed for deployment
    actions   = ["ecr:GetAuthorizationToken", "ecr-public:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions   = ["sts:GetServiceBearerToken"]
    resources = ["*"]
  }
}

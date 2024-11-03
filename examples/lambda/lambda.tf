data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "example" {
  name               = "example-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}
resource "aws_iam_role_policy_attachment" "example_basic_managed" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.example.name
}

resource "aws_lambda_function" "example" {
  function_name = "example"
  role          = aws_iam_role.example.arn

  image_uri     = "${aws_ecr_repository.example.repository_url}:${local.deployed_tag}"
  package_type  = "Image"
  architectures = ["x86_64"]
  publish       = true

  depends_on = [module.ecr_repo_image]
}

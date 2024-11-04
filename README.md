# Terraform Module Template


![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)

<!--- Replace repository name -->
![License](https://badgen.net/github/license/sterliakov/terraform-aws-ecr-image/)
![Release](https://badgen.net/github/release/sterliakov/terraform-aws-ecr-image/)

---


## USAGE

Push a dummy Alpine image to a newly created ECR repository:

```terraform
resource "aws_ecr_repository" "example" {
  name = "example"
}

module "ecr_repo_image" {
  source = "./ecr_curl"

  push_ecr_is_public = false
  push_repo_fqdn     = replace(aws_ecr_repository.example.repository_url, "//.*$/", "") # remove everything after first slash
  push_repo_name     = aws_ecr_repository.example.name
  push_image_tag     = "deployed"
}
```

## NOTES

* This module needs `curl` and `jq` on `PATH`.

## EXAMPLES

- [Lambda](examples/lambda) - Deploy a dummy image for Lambda (5 MB alpine by default)

<!-- BEGIN_TF_DOCS -->




## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_pull_ecr_is_public"></a> [pull\_ecr\_is\_public](#input\_pull\_ecr\_is\_public) | If the ECR repo we're pulling from is public (vs. private) | `bool` | `true` | no |
| <a name="input_pull_image_arch"></a> [pull\_image\_arch](#input\_pull\_image\_arch) | The arch of the image we're pulling, e.g. amd64 | `string` | `"amd64"` | no |
| <a name="input_pull_image_tag"></a> [pull\_image\_tag](#input\_pull\_image\_tag) | The tag of the image we're pulling, e.g. latest | `string` | `"3.20.3"` | no |
| <a name="input_pull_repo_fqdn"></a> [pull\_repo\_fqdn](#input\_pull\_repo\_fqdn) | The FQDN of the ECR repo we're pulling from, e.g. public.ecr.aws | `string` | `"public.ecr.aws"` | no |
| <a name="input_pull_repo_name"></a> [pull\_repo\_name](#input\_pull\_repo\_name) | The name of the ECR repo we're pulling from, e.g. my-repo | `string` | `"docker/library/alpine"` | no |
| <a name="input_push_ecr_is_public"></a> [push\_ecr\_is\_public](#input\_push\_ecr\_is\_public) | If the ECR repo we're pushing to is public (vs. private) | `bool` | `false` | no |
| <a name="input_push_image_tag"></a> [push\_image\_tag](#input\_push\_image\_tag) | The tag of the image we're pushing, e.g. latest | `string` | n/a | yes |
| <a name="input_push_repo_fqdn"></a> [push\_repo\_fqdn](#input\_push\_repo\_fqdn) | The FQDN of the ECR repo we're pushing to, e.g. 012345678910.dkr.ecr.<region-name>.amazonaws.com | `string` | n/a | yes |
| <a name="input_push_repo_name"></a> [push\_repo\_name](#input\_push\_repo\_name) | The name of the ECR repo we're pushing to, e.g. my-repo | `string` | n/a | yes |

## Modules

No modules.

## Outputs

No outputs.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.40.0 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.40.0 |

## Resources

| Name | Type |
|------|------|
| [terraform_data.ecr_repo_image](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |
| [aws_ecr_authorization_token.token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecr_authorization_token) | data source |
| [aws_ecrpublic_authorization_token.token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecrpublic_authorization_token) | data source |
<!-- END_TF_DOCS -->

## CONTRIBUTING

Contributions are very welcomed!

Start by reviewing [contribution guide](CONTRIBUTING.md) and our [code of conduct](CODE_OF_CONDUCT.md). After that, start coding and ship your changes by creating a new PR.

## LICENSE

Apache 2 Licensed. See [LICENSE](LICENSE) for full details.

variable "pull_ecr_is_public" {
  description = "If the ECR repo we're pulling from is public (vs. private)"
  type        = bool
  default     = true
}

variable "pull_repo_fqdn" {
  description = "The FQDN of the ECR repo we're pulling from, e.g. public.ecr.aws"
  type        = string
  default     = "public.ecr.aws"
}

variable "pull_repo_name" {
  description = "The name of the ECR repo we're pulling from, e.g. my-repo"
  type        = string
  default     = "docker/library/alpine"
}

variable "pull_image_tag" {
  description = "The tag of the image we're pulling, e.g. latest"
  type        = string
  default     = "3.20.3"
}

variable "pull_image_arch" {
  description = "The arch of the image we're pulling, e.g. amd64"
  type        = string
  default     = "amd64"
}

variable "push_ecr_is_public" {
  description = "If the ECR repo we're pushing to is public (vs. private)"
  type        = bool
  default     = false
}

variable "push_repo_fqdn" {
  description = "The FQDN of the ECR repo we're pushing to, e.g. 012345678910.dkr.ecr.<region-name>.amazonaws.com"
  type        = string
}

variable "push_repo_name" {
  description = "The name of the ECR repo we're pushing to, e.g. my-repo"
  type        = string
}

variable "push_image_tag" {
  description = "The tag of the image we're pushing, e.g. latest"
  type        = string
}

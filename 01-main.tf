provider "aws" {
  region = "ap-southeast-1"
}

locals {

  account_id  = data.aws_caller_identity.current.account_id
  prefix_name = "ecsbg"
  environment = "testing"

  git_url    = "https://github.com/aashari/terraform-sample-ecsbg.git"
  git_branch = "main"

  common_tags = {
    Name        = local.prefix_name
    Environment = local.environment
  }

  vpc_cidr_block       = "192.168.0.0/16"
  public_subnet_cidrs  = ["192.168.1.0/24", "192.168.2.0/24"]
  private_subnet_cidrs = ["192.168.3.0/24", "192.168.4.0/24"]
  availability_zones   = ["ap-southeast-1a", "ap-southeast-1b"]

}

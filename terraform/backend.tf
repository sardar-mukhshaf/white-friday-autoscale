# ------------------------------------------------------------------------------
# Remote State Configuration
# ------------------------------------------------------------------------------
terraform {
  backend "s3" {
    bucket         = "whitefriday-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "whitefriday-terraform-locks"
  }
}

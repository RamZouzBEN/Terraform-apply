terraform {
  backend "s3" {
    bucket         = "terraform-state-prod" # le bucket créé plus haut
    key            = "terraform-apply/infra/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locks-prod"
    encrypt        = true
  }
}

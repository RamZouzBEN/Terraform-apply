terraform {
  backend "s3" {
    bucket         = "terraformstatetst" # le bucket créé plus haut
    key            = "terraform-apply/infra/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-locks-TST"
    encrypt        = true
  }
}

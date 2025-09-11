provider "aws" {
  region = "eu-west-1"
}

data "aws_ssm_parameter" "ad_password" {
  name = "/domain/admin_password"
  with_decryption = true
}

data "aws_ami" "ec2windows" {
  most_recent      = true
  owners           = ["864899841353"]
  

}

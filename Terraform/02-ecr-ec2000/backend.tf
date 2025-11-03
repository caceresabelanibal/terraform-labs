terraform {
  backend "s3" {
    bucket         = "tf-labs-dev-tfstate-52563deb"
    key            = "02-ecr-ec2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-labs-dev-tf-lock"
    encrypt        = true
  }
}

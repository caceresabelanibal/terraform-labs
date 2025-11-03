terraform {
  backend "s3" {
    bucket         = "tf-labs-dev-tfstate-52563deb" # tu bucket actual
    key            = "stacks/vulneratrack/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-labs-dev-tf-lock"
    encrypt        = true
  }
}

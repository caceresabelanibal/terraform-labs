
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "repo_name" {
  type    = string
  default = "vulneratrack"
}

variable "repo_url" {
  type    = string
  default = "087581095532.dkr.ecr.us-east-1.amazonaws.com/vulneratrack"
}

variable "image_tag" {
  type    = string
  default = "v2"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}



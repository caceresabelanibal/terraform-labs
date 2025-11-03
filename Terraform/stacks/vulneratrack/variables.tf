variable "name" {
  type = string
}

variable "image_uri" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "repo_name" {
  type    = string
  default = "vulneratrack"
}
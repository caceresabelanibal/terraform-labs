variable "name" {
  description = "Nombre lógico para nombrar recursos (tag Name, SG, IAM, etc.)"
  type        = string
}

variable "image_uri" {
  description = "URI completo de la imagen en ECR (repo:tag)"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

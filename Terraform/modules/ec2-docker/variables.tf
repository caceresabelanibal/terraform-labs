variable "name" {
  description = "Nombre lógico para nombrar SG/Role/Profile/EC2"
  type        = string
}

variable "image_uri" {
  description = "Imagen completa en ECR (ej: 123456789012.dkr.ecr.us-east-1.amazonaws.com/app:v1)"
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.micro"
}

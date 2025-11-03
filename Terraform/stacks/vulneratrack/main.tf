module "app" {
  source        = "../../modules/ec2-docker"
  name          = "vulneratrack"
  image_uri     = var.image_uri
  instance_type = var.instance_type
}

output "public_ip" { value = module.app.public_ip }
output "public_dns" { value = module.app.public_dns }
output "app_url" {
  value = "http://${module.app.public_dns}"
}


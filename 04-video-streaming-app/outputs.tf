output "web_url" {
  value = "http://${module.compute.web_public_dns}"
}
output "input_bucket" {
  value = module.storage.input_bucket_id
}

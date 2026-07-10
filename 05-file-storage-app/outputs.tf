output "ui_url" {
  value = "http://${module.ui.public_dns}"
}
output "bucket_name" {
  value = module.storage.bucket_id
}

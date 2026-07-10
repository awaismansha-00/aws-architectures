output "application_url" {
  value = "http://${module.web.alb_dns_name}"
}
output "bucket_name" {
  value = module.storage.bucket_id
}
output "secret_name" {
  value = module.database.secret_name
}

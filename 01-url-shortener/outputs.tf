output "invoke_url" {
  value = module.api.invoke_url
}
output "api_key_id" {
  value = module.api.api_key_id
}
output "api_key_retrieval_command" {
  value = "aws apigateway get-api-key --api-key ${module.api.api_key_id} --include-value --query value --output text --region ${var.aws_region}"
}

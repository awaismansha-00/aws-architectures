output "invoke_url" {
  value = aws_api_gateway_stage.prod.invoke_url
}

output "api_key_id" {
  value = aws_api_gateway_api_key.client.id
}

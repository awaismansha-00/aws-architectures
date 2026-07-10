output "api_function_name" {
  value = aws_lambda_function.api.function_name
}

output "api_function_invoke_arn" {
  value = aws_lambda_function.api.invoke_arn
}

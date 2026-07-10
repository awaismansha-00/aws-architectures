output "create_function_name" {
  value = aws_lambda_function.create.function_name
}

output "create_function_invoke_arn" {
  value = aws_lambda_function.create.invoke_arn
}

output "redirect_function_name" {
  value = aws_lambda_function.redirect.function_name
}

output "redirect_function_invoke_arn" {
  value = aws_lambda_function.redirect.invoke_arn
}

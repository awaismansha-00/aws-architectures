output "handler_function_name" {
  value = aws_lambda_function.handler.function_name
}

output "handler_function_invoke_arn" {
  value = aws_lambda_function.handler.invoke_arn
}

output "handler_role_id" {
  value = aws_iam_role.handler.id
}

output "authorizer_function_name" {
  value = aws_lambda_function.authorizer.function_name
}

output "authorizer_function_invoke_arn" {
  value = aws_lambda_function.authorizer.invoke_arn
}

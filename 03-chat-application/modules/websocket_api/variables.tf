variable "name" {
  type = string
}

variable "handler_function_name" {
  type = string
}

variable "handler_function_invoke_arn" {
  type = string
}

variable "handler_role_id" {
  type = string
}

variable "authorizer_function_name" {
  type = string
}

variable "authorizer_function_invoke_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}

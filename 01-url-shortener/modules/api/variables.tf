variable "name" {
  type = string
}

variable "create_function_name" {
  type = string
}

variable "create_function_invoke_arn" {
  type = string
}

variable "redirect_function_name" {
  type = string
}

variable "redirect_function_invoke_arn" {
  type = string
}

variable "rate_limit" {
  type = number
}

variable "burst_limit" {
  type = number
}

variable "tags" {
  type = map(string)
}

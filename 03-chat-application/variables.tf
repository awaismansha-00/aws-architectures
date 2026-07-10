variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project_name" {
  type    = string
  default = "chat-app"
}
variable "environment" {
  type    = string
  default = "lab"
}
variable "connection_token" {
  type      = string
  sensitive = true
  validation {
    condition     = length(var.connection_token) >= 20
    error_message = "Use at least 20 characters."
  }
}
variable "tags" {
  type    = map(string)
  default = {}
}

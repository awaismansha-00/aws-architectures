variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project_name" {
  type    = string
  default = "url-shortener"
}
variable "environment" {
  type    = string
  default = "lab"
}
variable "tags" {
  type    = map(string)
  default = {}
}
variable "rate_limit" {
  type    = number
  default = 50
}
variable "burst_limit" {
  type    = number
  default = 100
}


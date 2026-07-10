variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project_name" {
  type    = string
  default = "blue-green"
}
variable "environment" {
  type    = string
  default = "lab"
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "green_traffic_weight" {
  type    = number
  default = 20
  validation {
    condition     = var.green_traffic_weight >= 0 && var.green_traffic_weight <= 100
    error_message = "Weight must be 0-100."
  }
}
variable "tags" {
  type    = map(string)
  default = {}
}

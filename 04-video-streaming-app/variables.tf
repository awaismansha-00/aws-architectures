variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project_name" {
  type    = string
  default = "video-streaming"
}
variable "environment" {
  type    = string
  default = "lab"
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "tags" {
  type    = map(string)
  default = {}
}

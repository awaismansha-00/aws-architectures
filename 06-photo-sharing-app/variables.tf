variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project_name" {
  type    = string
  default = "photo-sharing"
}
variable "environment" {
  type    = string
  default = "lab"
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "db_name" {
  type    = string
  default = "photoshare"
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]*$", var.db_name))
    error_message = "Invalid database name."
  }
}
variable "container_image" {
  type    = string
  default = "kodekloud/photosharing-app"
}
variable "tags" {
  type    = map(string)
  default = {}
}

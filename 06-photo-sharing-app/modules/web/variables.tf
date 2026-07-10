variable "name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "web_security_group_id" {
  type = string
}

variable "photo_bucket_id" {
  type = string
}

variable "photo_bucket_arn" {
  type = string
}

variable "db_secret_name" {
  type = string
}

variable "db_secret_arn" {
  type = string
}

variable "container_image" {
  type = string
}

variable "tags" {
  type = map(string)
}

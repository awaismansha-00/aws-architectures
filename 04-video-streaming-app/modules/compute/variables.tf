variable "name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "worker_security_group_id" {
  type = string
}

variable "web_security_group_id" {
  type = string
}

variable "input_bucket_id" {
  type = string
}

variable "input_bucket_arn" {
  type = string
}

variable "output_bucket_id" {
  type = string
}

variable "output_bucket_arn" {
  type = string
}

variable "catalog_table_name" {
  type = string
}

variable "catalog_table_arn" {
  type = string
}

variable "queue_url" {
  type = string
}

variable "queue_arn" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "tags" {
  type = map(string)
}

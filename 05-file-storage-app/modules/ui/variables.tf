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

variable "vpc_id" {
  type = string
}

variable "api_url" {
  type = string
}

variable "api_key" {
  type      = string
  sensitive = true
}

variable "tags" {
  type = map(string)
}

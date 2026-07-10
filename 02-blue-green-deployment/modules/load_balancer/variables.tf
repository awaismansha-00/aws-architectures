variable "name" {
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

variable "instance_ids" {
  type = map(string)
}

variable "green_traffic_weight" {
  type = number
}

variable "tags" {
  type = map(string)
}

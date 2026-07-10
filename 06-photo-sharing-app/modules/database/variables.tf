variable "name" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "db_security_group_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

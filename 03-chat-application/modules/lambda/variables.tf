variable "name" {
  type = string
}

variable "connections_table" {
  type = string
}

variable "connections_table_arn" {
  type = string
}

variable "history_table" {
  type = string
}

variable "history_table_arn" {
  type = string
}

variable "queue_url" {
  type = string
}

variable "queue_arn" {
  type = string
}

variable "connection_token" {
  type      = string
  sensitive = true
}

variable "tags" {
  type = map(string)
}

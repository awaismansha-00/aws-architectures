variable "name" {
  type = string
}

variable "bucket_id" {
  type = string
}

variable "bucket_arn" {
  type = string
}

variable "metadata_table" {
  type = string
}

variable "metadata_table_arn" {
  type = string
}

variable "queue_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "name" {
  type = string
}

variable "bucket_id" {
  type = string
}

variable "bucket_arn" {
  type = string
}

variable "source_account_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

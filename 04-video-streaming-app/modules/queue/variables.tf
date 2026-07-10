variable "name" {
  type = string
}

variable "input_bucket_id" {
  type = string
}

variable "input_bucket_arn" {
  type = string
}

variable "source_account_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

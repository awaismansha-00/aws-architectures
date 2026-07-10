output "instance_ids" {
  value = {
    for color, instance in aws_instance.web : color => instance.id
  }
}

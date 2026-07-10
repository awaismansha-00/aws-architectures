output "alb_url" {
  value = "http://${module.load_balancer.alb_dns_name}"
}
output "traffic_weights" {
  value = {
    blue  = 100 - var.green_traffic_weight,
    green = var.green_traffic_weight
  }
}

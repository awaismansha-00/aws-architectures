output "websocket_url" {
  value = "${module.websocket_api.invoke_url}?token=REDACTED"
}

output "controller_pip" {
  description = "Public IP for Kubernetes controller node"
  value       = azurerm_public_ip.controller_pip.ip_address
}

output "workers_pip" {
  description = "Public IP for Kubernetes worker nodes"
  value       = { for k, v in azurerm_public_ip.workers_pip : k => v.ip_address }
}

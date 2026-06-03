output "http_url" {
  description = "HTTP URL der VM"
  value       = "http://${exoscale_compute_instance.vm.public_ip_address}"
}

output "https_url" {
  description = "HTTPS URL der VM"
  value       = "https://${exoscale_compute_instance.vm.public_ip_address}"
}

output "api_url" {
  description = "JSON API URL der VM"
  value       = "http://${exoscale_compute_instance.vm.public_ip_address}/api"
}
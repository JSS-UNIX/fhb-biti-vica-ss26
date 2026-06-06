# ============================================================
# outputs.tf – Ausgabewerte nach erfolgreichem Apply
# Diese Werte werden im GitHub Actions Log angezeigt
# ============================================================

output "vm_public_ip" {
  description = "Öffentliche IP-Adresse der VM"
  value       = exoscale_compute_instance.vm_info.public_ip_address
}

output "vm_info_url" {
  description = "URL des VM-Info HTTP-Endpunkts"
  value       = "http://${exoscale_compute_instance.vm_info.public_ip_address}"
}

output "vm_name" {
  description = "Name der erstellten VM"
  value       = exoscale_compute_instance.vm_info.name
}

output "vm_zone" {
  description = "Exoscale Zone der VM"
  value       = var.zone
}

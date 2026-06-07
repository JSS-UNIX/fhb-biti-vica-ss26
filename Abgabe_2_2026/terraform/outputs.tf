# =============================================================================
# outputs.tf — Ausgabewerte nach terraform apply
# =============================================================================

# Öffentliche IP-Adresse der Elastic IP
output "public_ip" {
  description = "Öffentliche IP-Adresse der VM"
  value       = exoscale_elastic_ip.web_eip.ip_address
}

# HTTP URL (immer verfügbar)
output "http_url" {
  description = "HTTP URL der Website"
  value       = "http://${exoscale_elastic_ip.web_eip.ip_address}"
}

# HTTPS URL (nur wenn Domain gesetzt)
output "https_url" {
  description = "HTTPS URL (nur wenn dns_domain gesetzt)"
  value       = local.dns_enabled ? "https://${local.fqdn}" : "Kein Domain-Name konfiguriert"
}

# JSON API URL
output "api_url" {
  description = "JSON API Endpunkt"
  value       = local.dns_enabled ? "https://${local.fqdn}/api" : "http://${exoscale_elastic_ip.web_eip.ip_address}/api"
}

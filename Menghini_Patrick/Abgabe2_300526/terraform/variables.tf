# Platzhalter für den Exoscale API-Key
variable "exoscale_key" {
  type        = string
  description = "API Key für den Exoscale Account"
  sensitive   = true # Verhindert, dass der Key aus Versehen in Logs angezeigt wird
}

# Platzhalter für das Exoscale API-Secret (Passwort)
variable "exoscale_secret" {
  type        = string
  description = "API Secret für den Exoscale Account"
  sensitive   = true # Verhindert, dass das Secret aus Versehen in Logs angezeigt wird
}

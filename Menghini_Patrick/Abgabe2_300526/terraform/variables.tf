# Platzhalter fuer den Exoscale API-Key
variable "exoscale_key" {
  type        = string
  description = "API Key fuer den Exoscale Account"
  sensitive   = true
}

# Platzhalter fuer das Exoscale API-Secret (Passwort)
variable "exoscale_secret" {
  type        = string
  description = "API Secret fuer den Exoscale Account"
  sensitive   = true
}

# ============================================================
# variables.tf – Eingabevariablen für die Terraform Konfiguration
# ============================================================

variable "zone" {
  description = "Exoscale Zone, in der die VM erstellt wird"
  type        = string
  default     = "at-vie-1"
}

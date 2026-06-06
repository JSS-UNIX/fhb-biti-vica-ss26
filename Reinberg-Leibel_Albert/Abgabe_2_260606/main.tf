terraform {
  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
      version = "0.69.2"
    }
  }
}

# Provider Konfiguration bleibt leer
# Terraform nutzt automatisch EXOSCALE_API_KEY und EXOSCALE_API_SECRET
provider "exoscale" {
}

locals {
  zone       = "ch-gva-2"                       
  template   = "Linux Ubuntu 26.04 LTS 64-bit"
}

# ... (Der restliche Code bleibt exakt gleich wie vorher) ...
# Definition des benötigten Terraform Providers für Exoscale
terraform {
  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
      version = "~> 0.64"
    }
  }
}

# Verbindung zu Exoscale
# Die Zugangsdaten kommen später automatisch aus GitHub Secrets
provider "exoscale" {
  key    = var.exoscale_key
  secret = var.exoscale_secret
}


# Security Group (Firewall) für die virtuelle Maschine
resource "exoscale_security_group" "web" {

  name = "ebin-vica-security-group"


  # SSH Zugriff für Administration erlauben
  ingress {
    protocol  = "TCP"
    ports     = ["22"]
    cidr_list = ["0.0.0.0/0"]
  }


  # HTTP Zugriff für Webseite erlauben
  ingress {
    protocol  = "TCP"
    ports     = ["80"]
    cidr_list = ["0.0.0.0/0"]
  }
}


# Erstellung der Ubuntu VM in Exoscale
resource "exoscale_compute_instance" "vm" {

  name = "ebin-vica-vm"

  # Standort Wien
  zone = "at-vie-1"

  # Ubuntu Betriebssystem
  template = "Linux Ubuntu 24.04 LTS 64-bit"

  # kleine VM ausreichend für Webserver
  type = "standard.micro"

  # Speichergröße
  disk_size = 10


  # Firewall zuweisen
  security_group_ids = [
    exoscale_security_group.web.id
  ]


  # CloudInit führt die komplette Linux Konfiguration automatisch aus
  user_data = file("${path.module}/cloud-init.yaml")
}
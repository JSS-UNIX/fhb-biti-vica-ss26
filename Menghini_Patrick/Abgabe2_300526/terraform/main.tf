# Terraform-Einstellungen und Provider-Definition
terraform {
  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
      version = "~> 0.53.0"
    }
  }
}

# Verbindung zu Exoscale mit den Zugangsdaten herstellen
provider "exoscale" {
  key    = var.exoscale_key
  secret = var.exoscale_secret
}

# Security Group (Firewall) anlegen
resource "exoscale_security_group" "web_sg" {
  name        = "pmen-web-sg"
  description = "Erlaubt eingehenden HTTP-Verkehr auf Port 80"
}

# Regel: Erlaube HTTP (Port 80) von ueberall
resource "exoscale_security_group_rule" "http_rule" {
  security_group_id = exoscale_security_group.web_sg.id
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = "0.0.0.0/0"
  start_port        = 80
  end_port          = 80
}

# Automatische Suche nach dem aktuellen Ubuntu Template
data "exoscale_template" "ubuntu" {
  zone = "at-vie-1"
  name = "Linux Ubuntu 24.04 LTS 64-bit"
}

# Erstellen der VM
resource "exoscale_compute_instance" "sysinfo_vm" {
  zone        = "at-vie-1"
  name        = "pmen-sysinfo-vm"
  type        = "standard.micro"
  disk_size   = 10
  template_id = data.exoscale_template.ubuntu.id

  # Personalisierte Firewall an die VM haengen
  security_group_ids = [exoscale_security_group.web_sg.id]

  # Das Cloud-Init-Skript einlesen und an die VM uebergeben
  # Wird beim ersten Boot automatisch ausgefuehrt
  user_data = file("${path.module}/cloud-init.yaml")
}

# Gibt nach dem erfolgreichen Setup die URL der VM aus
output "vm_url" {
  value       = "http://${exoscale_compute_instance.sysinfo_vm.public_ip_address}"
  description = "Die fertige URL zum HTTP-Endpunkt mit den Systemdetails"
}
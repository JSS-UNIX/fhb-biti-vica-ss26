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
  name        = "pmen753-web-sg"
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
  name        = "pmen753-sysinfo-vm"
  type        = "standard.micro"
  disk_size   = 10
  template_id = data.exoscale_template.ubuntu.id

  security_group_ids = [exoscale_security_group.web_sg.id]

  user_data = file("${path.module}/cloud-init.yaml")
}

output "vm_url" {
  value       = "http://${exoscale_compute_instance.sysinfo_vm.public_ip_address}"
  description = "Die fertige URL zum HTTP-Endpunkt mit den Systemdetails"
}

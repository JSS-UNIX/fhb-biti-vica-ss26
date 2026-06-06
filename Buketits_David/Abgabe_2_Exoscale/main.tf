# ============================================================
# main.tf – Exoscale Infrastruktur für die VM-Info Webseite
# Erstellt eine Ubuntu VM mit HTTP-Endpunkt via CloudInit
# ============================================================

terraform {
  required_providers {
    exoscale = {
      # Offizieller Exoscale Terraform Provider
      source  = "exoscale/exoscale"
      version = "~> 0.62"
    }
  }
}

# Provider-Konfiguration: Credentials kommen aus Umgebungsvariablen
# EXOSCALE_API_KEY und EXOSCALE_API_SECRET (werden via GitHub Secrets gesetzt)
provider "exoscale" {}

# ============================================================
# Security Group: Firewall-Regeln für die VM
# ============================================================
resource "exoscale_security_group" "vm_info_sg" {
  name        = "vm-info-sg"
  description = "Security Group fuer die VM-Info Webseite"
}

# Regel: SSH-Zugang (Port 22) von überall erlaubt
resource "exoscale_security_group_rule" "ssh" {
  security_group_id = exoscale_security_group.vm_info_sg.id
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = "0.0.0.0/0"
  start_port        = 22
  end_port          = 22
}

# Regel: HTTP-Zugang (Port 80) von überall erlaubt
resource "exoscale_security_group_rule" "http" {
  security_group_id = exoscale_security_group.vm_info_sg.id
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = "0.0.0.0/0"
  start_port        = 80
  end_port          = 80
}

# Regel: ICMP (Ping) erlaubt für Debugging
resource "exoscale_security_group_rule" "icmp" {
  security_group_id = exoscale_security_group.vm_info_sg.id
  type              = "INGRESS"
  protocol          = "ICMP"
  cidr              = "0.0.0.0/0"
  icmp_type         = 8  # Echo Request
  icmp_code         = 0
}

# ============================================================
# CloudInit User-Data: Konfiguriert das OS automatisch
# Die template_file liest cloud-init.yaml und übergibt Variablen
# ============================================================
data "template_file" "cloud_init" {
  template = file("${path.module}/cloud-init.yaml")
}

# ============================================================
# Compute Instance: Die eigentliche VM auf Exoscale
# ============================================================
resource "exoscale_compute_instance" "vm_info" {
  # Anzeigename der VM in der Exoscale Console
  name = "vm-info-server"

  # Ubuntu 24.04 LTS (Noble Numbat) – unterstütztes Ubuntu
  template_id = data.exoscale_template.ubuntu.id

  # Instance-Typ: small für Demo-Zwecke (2 vCPU, 2 GB RAM)
  type = "standard.small"

  # Disk-Größe in GB
  disk_size = 20

  # Zone: at-vie-1 (Wien, Österreich)
  zone = var.zone

  # Firewall-Regeln anwenden
  security_group_ids = [exoscale_security_group.vm_info_sg.id]

  # CloudInit Script wird beim ersten Boot ausgeführt
  user_data = data.template_file.cloud_init.rendered

  # Lifecycle-Hook: Verhindert Neuerstellen bei kleinen Änderungen
  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================
# Template Lookup: Sucht das aktuelle Ubuntu 24.04 LTS Image
# ============================================================
data "exoscale_template" "ubuntu" {
  zone   = var.zone
  # Sucht nach dem neuesten offiziellen Ubuntu 24.04 Template
  name   = "Linux Ubuntu 24.04 (Noble Numbat) 64-bit"
}

# =============================================================================
# main.tf — Exoscale VM Infrastruktur
# =============================================================================
# Erstellt eine Ubuntu VM auf Exoscale, die technische System-Informationen
# über zwei HTTP-Endpunkte bereitstellt:
#   /        → HTML-Website mit visueller Darstellung
#   /api     → JSON-API mit maschinenlesbaren Daten
# =============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
      version = "~> 0.59"
    }
  }

  # Remote State wird in einem Exoscale SOS Bucket gespeichert (S3-kompatibel).
  # Zugangsdaten werden über GitHub Secrets als Umgebungsvariablen gesetzt.
  backend "s3" {}
}

# -----------------------------------------------------------------------------
# Provider Konfiguration
# -----------------------------------------------------------------------------
provider "exoscale" {
  # API-Schlüssel werden als Umgebungsvariablen erwartet:
  #   EXOSCALE_API_KEY
  #   EXOSCALE_API_SECRET
}

# -----------------------------------------------------------------------------
# cloud-init Konfiguration als Template laden
# -----------------------------------------------------------------------------
# templatefile() liest die YAML-Datei und ersetzt Variablen (z.B. domain_name)
locals {
  # cloud-init Konfiguration mit eingesetztem Domain-Namen
  cloud_init_rendered = templatefile("${path.module}/cloud_init.yaml", {
    domain_name = var.domain_name
  })

  # Hilfsvariable: ist ein Domain-Name gesetzt?
  dns_enabled = var.domain_name != ""
}

# -----------------------------------------------------------------------------
# Security Group: erlaubt eingehenden HTTP (80), HTTPS (443) und SSH (22)
# -----------------------------------------------------------------------------
resource "exoscale_security_group" "web_sg" {
  name        = "${var.instance_name}-sg"
  description = "Security Group fuer die VICA Web-VM (HTTP/HTTPS/SSH)"
}

# Regel: SSH (Port 22)
resource "exoscale_security_group_rule" "ssh" {
  security_group_id = exoscale_security_group.web_sg.id
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = var.ssh_allowed_cidr
  start_port        = 22
  end_port          = 22
}

# Regel: HTTP (Port 80) — öffentlich erreichbar
resource "exoscale_security_group_rule" "http" {
  security_group_id = exoscale_security_group.web_sg.id
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = "0.0.0.0/0"
  start_port        = 80
  end_port          = 80
}

# Regel: HTTPS (Port 443) — öffentlich erreichbar
resource "exoscale_security_group_rule" "https" {
  security_group_id = exoscale_security_group.web_sg.id
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = "0.0.0.0/0"
  start_port        = 443
  end_port          = 443
}

# Regel: ICMP (Ping) — für Debugging
resource "exoscale_security_group_rule" "icmp" {
  security_group_id = exoscale_security_group.web_sg.id
  type              = "INGRESS"
  protocol          = "ICMP"
  cidr              = "0.0.0.0/0"
  icmp_type         = 8
  icmp_code         = 0
}

# -----------------------------------------------------------------------------
# SSH Public Key — für Notfall-Login
# -----------------------------------------------------------------------------
resource "exoscale_ssh_key" "deployer" {
  name       = "${var.instance_name}-key"
  public_key = var.ssh_public_key
}

# -----------------------------------------------------------------------------
# Ubuntu 24.04 LTS Template aus Exoscale Community Templates
# -----------------------------------------------------------------------------
data "exoscale_compute_template" "ubuntu" {
  zone   = var.zone
  name   = "Linux Ubuntu 24.04 (Jammy Jellyfish) 64-bit"
  filter = "community"
}

# -----------------------------------------------------------------------------
# Compute Instance (Ubuntu VM)
# -----------------------------------------------------------------------------
resource "exoscale_compute_instance" "web_vm" {
  name = var.instance_name
  zone = var.zone

  # Ubuntu 24.04 LTS
  template_id = data.exoscale_compute_template.ubuntu.id

  # Instanztyp: standard.small = 2 vCPU, 2 GB RAM
  type = var.instance_type

  # Festplattengröße in GB
  disk_size = var.disk_size

  # Security Group zuweisen
  security_group_ids = [exoscale_security_group.web_sg.id]

  # SSH-Key für Notfall-Zugriff
  ssh_key = exoscale_ssh_key.deployer.name

  # cloud-init Konfiguration — vollautomatische OS-Konfiguration
  user_data = local.cloud_init_rendered

  # Labels für Übersicht im Exoscale Portal
  labels = {
    project     = "fhb-biti-vica"
    environment = "assignment"
    managed_by  = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Elastic IP (EIP) — statische öffentliche IP-Adresse
# -----------------------------------------------------------------------------
resource "exoscale_elastic_ip" "web_eip" {
  zone        = var.zone
  description = "Statische IP fuer ${var.instance_name}"

  # Exoscale überwacht den HTTP-Endpunkt automatisch
  healthcheck {
    mode            = "http"
    port            = 80
    uri             = "/health"
    interval        = 10
    timeout         = 5
    strikes_ok      = 2
    strikes_fail    = 3
  }
}

# EIP der VM zuweisen
resource "exoscale_compute_instance_elastic_ip" "web_eip_attach" {
  instance_id   = exoscale_compute_instance.web_vm.id
  elastic_ip_id = exoscale_elastic_ip.web_eip.id
  zone          = var.zone
}

# -----------------------------------------------------------------------------
# DNS Record (optional — nur wenn domain_name gesetzt)
# -----------------------------------------------------------------------------
resource "exoscale_domain" "main" {
  count = local.dns_enabled ? 1 : 0
  name  = var.dns_zone
}

resource "exoscale_domain_record" "web_a" {
  count       = local.dns_enabled ? 1 : 0
  domain_id   = exoscale_domain.main[0].id
  name        = var.dns_record_name
  record_type = "A"
  content     = exoscale_elastic_ip.web_eip.ip_address
  ttl         = 300
}

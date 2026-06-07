# =============================================================================
# main.tf — Exoscale VM Infrastruktur
# =============================================================================
# Erstellt eine Ubuntu VM auf Exoscale mit zwei HTTP-Endpunkten:
#   /        → HTML-Website mit Systeminfos
#   /api     → JSON-API mit Systeminfos
# =============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    # Exoscale Provider — verwaltet VMs, Security Groups, Elastic IPs, DNS
    exoscale = {
      source  = "exoscale/exoscale"
      version = "~> 0.59"
    }
  }

  # State wird in Exoscale SOS gespeichert (S3-kompatibel).
  # Zugangsdaten kommen via -backend-config im GitHub Actions Workflow.
  backend "s3" {}
}

# -----------------------------------------------------------------------------
# Provider: Exoscale API Credentials
# Werden als TF_VAR_exoscale_api_key / TF_VAR_exoscale_api_secret gesetzt.
# -----------------------------------------------------------------------------
provider "exoscale" {
  key    = var.exoscale_api_key
  secret = var.exoscale_api_secret
}

# -----------------------------------------------------------------------------
# Lokale Hilfsvariablen
# -----------------------------------------------------------------------------
locals {
  # Ist ein DNS-Domain gesetzt? Steuert ob DNS-Ressourcen erstellt werden.
  dns_enabled = var.dns_domain != ""

  # Vollständiger FQDN, z.B. vm-details.example.com
  fqdn = local.dns_enabled ? "${var.dns_record_name}.${var.dns_domain}" : ""

  # cloud-init Template mit eingesetzten Werten rendern
  cloud_init_rendered = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    fqdn = local.fqdn
	letsencrypt_email = var.letsencrypt_email
  })
}

# -----------------------------------------------------------------------------
# Security Group — Firewall-Regeln für die VM
# -----------------------------------------------------------------------------
resource "exoscale_security_group" "web_sg" {
  name        = "${var.instance_name}-sg"
  description = "Security Group fuer VICA Web-VM"
}

# HTTP (Port 80) — öffentlich erreichbar
resource "exoscale_security_group_rule" "http" {
  security_group_id = exoscale_security_group.web_sg.id
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = "0.0.0.0/0"
  start_port        = 80
  end_port          = 80
}

# HTTPS (Port 443) — öffentlich erreichbar
resource "exoscale_security_group_rule" "https" {
  security_group_id = exoscale_security_group.web_sg.id
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = "0.0.0.0/0"
  start_port        = 443
  end_port          = 443
}

# SSH (Port 22) — nur wenn ssh_allowed_cidr gesetzt ist
resource "exoscale_security_group_rule" "ssh" {
  count             = var.ssh_allowed_cidr != "" ? 1 : 0
  security_group_id = exoscale_security_group.web_sg.id
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = var.ssh_allowed_cidr
  start_port        = 22
  end_port          = 22
}

# ICMP (Ping) — für Debugging
resource "exoscale_security_group_rule" "icmp" {
  security_group_id = exoscale_security_group.web_sg.id
  type              = "INGRESS"
  protocol          = "ICMP"
  cidr              = "0.0.0.0/0"
  icmp_type         = 8
  icmp_code         = 0
}

# -----------------------------------------------------------------------------
# SSH Key — optional, nur wenn ssh_public_key gesetzt
# -----------------------------------------------------------------------------
resource "exoscale_ssh_key" "deployer" {
  count      = var.ssh_public_key != "" ? 1 : 0
  name       = "${var.instance_name}-key"
  public_key = var.ssh_public_key
}

# -----------------------------------------------------------------------------
# Elastic IP — statische öffentliche IP-Adresse
# Bleibt gleich auch nach VM-Neustart; kann DNS zugewiesen werden.
# -----------------------------------------------------------------------------
resource "exoscale_elastic_ip" "web_eip" {
  zone        = var.zone
  description = "Statische IP fuer ${var.instance_name}"

  # Exoscale prueft den Healthcheck-Endpunkt automatisch
  healthcheck {
    mode         = "http"
    port         = 80
    uri          = "/health"
    interval     = 10
    timeout      = 5
    strikes_ok   = 2
    strikes_fail = 3
  }
}

# -----------------------------------------------------------------------------
# Compute Instance (Ubuntu VM)
# -----------------------------------------------------------------------------
resource "exoscale_compute_instance" "web_vm" {
  name = var.instance_name
  zone = var.zone

  # Ubuntu Template — Name aus variables.tf (Standard: Ubuntu 22.04 LTS)
  template_id = data.exoscale_template.ubuntu.id

  # Instanztyp (standard.small = 2 vCPU, 2 GB RAM)
  type = var.instance_type

  # Festplattengröße in GiB
  disk_size = var.disk_size

  # Security Group zuweisen
  security_group_ids = [exoscale_security_group.web_sg.id]

  # Elastic IP direkt bei der VM registrieren
  elastic_ip_ids = [exoscale_elastic_ip.web_eip.id]

  # SSH Key nur wenn angegeben
  ssh_key = var.ssh_public_key != "" ? exoscale_ssh_key.deployer[0].name : null

  # cloud-init: vollautomatische OS-Konfiguration beim ersten Boot
  user_data = local.cloud_init_rendered

  # Labels für Übersicht im Exoscale Portal
  labels = {
    project    = "fhb-biti-vica"
    managed_by = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Ubuntu Template aus Exoscale
# -----------------------------------------------------------------------------
data "exoscale_template" "ubuntu" {
  zone = var.zone
  name = var.template_name
}

# -----------------------------------------------------------------------------
# DNS Record (optional — nur wenn dns_domain gesetzt)
# -----------------------------------------------------------------------------
resource "exoscale_domain_record" "web_a" {
  count       = local.dns_enabled ? 1 : 0
  domain      = var.dns_domain
  name        = var.dns_record_name
  record_type = "A"
  content     = exoscale_elastic_ip.web_eip.ip_address
  ttl         = 300
}

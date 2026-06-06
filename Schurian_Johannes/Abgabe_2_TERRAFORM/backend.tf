# ============================================================
# backend.tf – Remote State Konfiguration
#
# Der Terraform State wird in einem Exoscale S3-kompatiblen
# Object Storage Bucket gespeichert, damit GitHub Actions
# bei jedem Workflow-Run auf den aktuellen State zugreifen kann.
#
# WICHTIG: Der Bucket muss manuell einmalig in Exoscale erstellt werden,
# BEVOR der erste Workflow-Run ausgeführt wird!
# Bucket Name: terraform-state-schurian (oder eigener Name in Secrets)
# ============================================================

terraform {
  backend "s3" {
    # Exoscale S3-kompatibler Endpunkt für Wien
    endpoint = "https://sos-at-vie-1.exo.io"

    # Bucket-Name (wird via GitHub Secret TERRAFORM_STATE_BUCKET gesetzt)
    # Oder direkt hier eintragen:
    bucket = "terraform-state-schurian"

    # Pfad zur State-Datei im Bucket
    key = "vm-info/terraform.tfstate"

    # Exoscale verwendet S3-kompatible Authentifizierung
    # Credentials kommen aus Umgebungsvariablen:
    # AWS_ACCESS_KEY_ID = EXOSCALE_API_KEY
    # AWS_SECRET_ACCESS_KEY = EXOSCALE_API_SECRET
    region = "at-vie-1"

    # Pflichtfelder für S3-Backend (bei Exoscale deaktiviert)
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
}

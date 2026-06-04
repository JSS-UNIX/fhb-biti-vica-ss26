terraform {
  backend "s3" {
    bucket                      = "fblazovich-tofu-state"
    key                         = "terraform.tfstate"
    region                      = "at-vie-1"
    endpoints                   = { s3 = "https://sos-at-vie-1.exo.io" }

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
terraform {
  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
      version = "~> 0.68.0"
    }
  }
}

provider "exoscale" {
  key = var.exoscale_key
  secret = var.exoscale_secret
}

data "exoscale_template" "ubuntu" {
  zone = var.zone
  name = var.ubuntu_template
}

resource "exoscale_compute_instance" "vm" {
  zone = var.zone
  name = var.vm_name

  template_id = data.exoscale_template.ubuntu.id
  type        = var.instance_type
  disk_size   = var.disk_size
  security_group_ids = [exoscale_security_group.my_security_group.id]
  ssh_keys           = [exoscale_ssh_key.ssh.id]
}

resource "exoscale_ssh_key" "ssh" {
  name       = "ssh-key"
  public_key = var.ssh_public_key
}
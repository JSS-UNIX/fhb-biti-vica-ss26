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
  security_group_ids = [exoscale_security_group.fblazovich_sec_group.id]
  user_data = file("${path.module}/cloud-init.yml")
}

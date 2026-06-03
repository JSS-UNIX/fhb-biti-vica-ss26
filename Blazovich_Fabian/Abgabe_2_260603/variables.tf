variable "zone" {
    description = "Exoscale Zone"
    type = string
    default = "at-vie-2"
}

variable "vm_name" {
    description = "Name der VM"
    type = string
    default = "f-blazovich-vm"
}

variable "disk_size" {
    description = "Disk Größe in GB"
    type = number
    default = 15
}

variable "instance_type" {
    description = "VM Größe"
    type = string
    default = "standard.small"
}

variable "ubuntu_template" {
    description = "Ubuntu-Image, welches für die VM verwendet wird"
    type = string
    default = "Ubuntu 22.04.5 LTS 64-bit"
}

variable "exoscale_key" {
    description = "Exoscale Key"
    type = string
    sensitive = true
}

variable "exoscale_secret" {
    description = "Exoscale Secret"
    type = string
    sensitive = true
}
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
    descritpion = "Disk Größe in GB"
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
    type = "string"
    default = "Ubuntu 22.04.5 LTS 64-bit"
}
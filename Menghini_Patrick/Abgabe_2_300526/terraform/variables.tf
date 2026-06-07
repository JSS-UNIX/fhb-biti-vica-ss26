variable "exoscale_api_key" {
  type      = string
  sensitive = true
}

variable "exoscale_api_secret" {
  type      = string
  sensitive = true
}

variable "zone" {
  type    = string
  default = "at-vie-1"
}

variable "instance_template" {
  type    = string
  default = "Linux Ubuntu 26.04 LTS 64-bit"
}

variable "instance_name" {
  type    = string
  default = "pmen-vm"
}

variable "instance_type" {
  type    = string
  default = "standard.micro"
}

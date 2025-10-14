variable "ubuntu_version" {
  type    = string
  default = "noble"
}

variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API endpoint"
}

variable "default_gateway" {
  type        = string
  description = "Network gateway IP"
}

variable "ssh_key" {
  type        = string
  description = "Path to public key for SSH"
}

variable "ubuntu_cp_01_ip_addr" {
  type = string
}

variable "ubuntu_cp_02_ip_addr" {
  type = string
}

variable "ubuntu_cp_03_ip_addr" {
  type = string
}

variable "ubuntu_worker_01_ip_addr" {
  type = string
}

variable "ubuntu_worker_02_ip_addr" {
  type = string
}

variable "ubuntu_worker_03_ip_addr" {
  type = string
}

variable "ubuntu_haproxy_01_ip_addr" {
  type = string
}
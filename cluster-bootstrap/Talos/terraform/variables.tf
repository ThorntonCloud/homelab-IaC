variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API endpoint"
}

variable "api_token" {
  type        = string
  description = "Proxmox user + API Token"
}

variable "default_gateway" {
  type        = string
  description = "Network gateway IP"
}

variable "talos_cidr" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "talos_cp_01_ip_addr" {
  type = string
}

variable "talos_cp_02_ip_addr" {
  type = string
}

variable "talos_cp_03_ip_addr" {
  type = string
}

variable "talos_worker_01_ip_addr" {
  type = string
}

variable "talos_worker_02_ip_addr" {
  type = string
}

variable "talos_worker_03_ip_addr" {
  type = string
}

variable "cp_vip" {
  type = string
}

variable "talos_version" {
  type    = string
  default = "v1.11.5"
}

variable "kubernetes_version" {
  type    = string
  default = "1.34.1"
}
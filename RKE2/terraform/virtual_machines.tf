data "local_file" "ssh_public_key" {
  filename = var.ssh_key
}

resource "proxmox_virtual_environment_vm" "ubuntu_cp_01" {
  name        = "rke2-cp-01"
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = "pve"
  on_boot     = true

  initialization {
    datastore_id = "ProxStorage"
    ip_config {
      ipv4 {
        address = "${var.ubuntu_cp_01_ip_addr}/${var.rke2_cidr}"
        gateway = var.default_gateway
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "ProxStorage"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  operating_system {
    type = "l26"
  }

  network_device {
    bridge = "vmbr0"
  }
}

resource "proxmox_virtual_environment_vm" "ubuntu_cp_02" {
  name        = "rke2-cp-02"
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = "pve"
  on_boot     = true

  initialization {
    datastore_id = "ProxStorage"
    ip_config {
      ipv4 {
        address = "${var.ubuntu_cp_02_ip_addr}/${var.rke2_cidr}"
        gateway = var.default_gateway
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "ProxStorage"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  operating_system {
    type = "l26"
  }

  network_device {
    bridge = "vmbr0"
  }
}

resource "proxmox_virtual_environment_vm" "ubuntu_cp_03" {
  name        = "rke2-cp-03"
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = "pve"
  on_boot     = true

  initialization {
    datastore_id = "ProxStorage"
    ip_config {
      ipv4 {
        address = "${var.ubuntu_cp_03_ip_addr}/${var.rke2_cidr}"
        gateway = var.default_gateway
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  disk {
    datastore_id = "ProxStorage"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  operating_system {
    type = "l26"
  }

  network_device {
    bridge = "vmbr0"
  }
}

resource "proxmox_virtual_environment_vm" "ubuntu_worker_01" {
  name        = "rke2-worker-01"
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = "pve"
  on_boot     = true

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "ProxStorage"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    file_format  = "raw"
    interface    = "virtio0"
    size         = 20
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = "ProxStorage"
    ip_config {
      ipv4 {
        address = "${var.ubuntu_worker_01_ip_addr}/${var.rke2_cidr}"
        gateway = var.default_gateway
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
  }
}

resource "proxmox_virtual_environment_vm" "ubuntu_worker_02" {
  name        = "rke2-worker-02"
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = "pve"
  on_boot     = true

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "ProxStorage"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    file_format  = "raw"
    interface    = "virtio0"
    size         = 20
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = "ProxStorage"
    ip_config {
      ipv4 {
        address = "${var.ubuntu_worker_02_ip_addr}/${var.rke2_cidr}"
        gateway = var.default_gateway
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
  }
}

resource "proxmox_virtual_environment_vm" "ubuntu_worker_03" {
  name        = "rke2-worker-03"
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = "pve"
  on_boot     = true

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "ProxStorage"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    file_format  = "raw"
    interface    = "virtio0"
    size         = 20
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = "ProxStorage"
    ip_config {
      ipv4 {
        address = "${var.ubuntu_worker_03_ip_addr}/${var.rke2_cidr}"
        gateway = var.default_gateway
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
  }
}

resource "proxmox_virtual_environment_vm" "ubuntu_haproxy_01" {
  name        = "rke2-haproxy-01"
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = "pve"
  on_boot     = true

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "ProxStorage"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    file_format  = "raw"
    interface    = "virtio0"
    size         = 20
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = "ProxStorage"
    ip_config {
      ipv4 {
        address = "${var.ubuntu_haproxy_01_ip_addr}/${var.rke2_cidr}"
        gateway = var.default_gateway
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [trimspace(data.local_file.ssh_public_key.content)]
    }
  }
}
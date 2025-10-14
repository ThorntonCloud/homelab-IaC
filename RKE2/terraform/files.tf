locals {
  ubuntu = {
    version = var.ubuntu_version
  }
}

resource "proxmox_virtual_environment_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = "ProxStorage"
  node_name    = "pve"
  file_name    = "ubuntu-server-${local.ubuntu.version}-cloudimg-amd64.img"
  url          = "https://cloud-images.ubuntu.com/${local.ubuntu.version}/current/${local.ubuntu.version}-server-cloudimg-amd64.img"
  overwrite    = false

  lifecycle {
    create_before_destroy = false
  }
}
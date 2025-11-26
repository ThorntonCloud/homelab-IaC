# Talos Image Management
#
# Handles downloading and uploading the Talos Linux image to Proxmox.
#
# Process:
# 1. Downloads the Talos nocloud image (raw.gz) from the official factory.
# 2. Decompresses the image to a raw format.
# 3. Uploads the raw image to the Proxmox storage.

locals {
  talos = {
    version = var.talos_version
  }
}

# Download and Decompress Image
# Uses a local-exec provisioner to fetch the image.
# This avoids checking large binary files into git.
resource "null_resource" "download_talos_local" {
  triggers = {
    version = local.talos.version
  }

  provisioner "local-exec" {
    command = <<-EOT
      wget -O /tmp/talos-${local.talos.version}-nocloud-amd64.raw.gz \
        'https://factory.talos.dev/image/376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba/${local.talos.version}/nocloud-amd64.raw.gz' && \
      gunzip -f /tmp/talos-${local.talos.version}-nocloud-amd64.raw.gz
    EOT
  }
}

# Upload Image to Proxmox
# Uploads the decompressed raw image to the specified Proxmox datastore.
# This image is then used as the boot disk for the VMs.
resource "proxmox_virtual_environment_file" "talos_nocloud_image" {
  depends_on = [null_resource.download_talos_local]

  content_type = "iso"
  datastore_id = "ProxStorage"
  node_name    = "pve"

  source_file {
    path      = "/tmp/talos-${local.talos.version}-nocloud-amd64.raw"
    file_name = "talos-${local.talos.version}-nocloud-amd64.img"
  }
}
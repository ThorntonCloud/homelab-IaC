locals {
  talos = {
    version = var.talos_version
  }
}

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
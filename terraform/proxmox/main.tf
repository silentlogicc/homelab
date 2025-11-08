provider "proxmox" {
  endpoint  = var.pm_api_url
  api_token = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  insecure  = true

  ssh {
    username = "root"
    agent    = true
  }
}

# Cloud-Init Snippet (wird auf Storage "local" abgelegt – dort muss "Snippets" aktiviert sein)
resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local" # ggf. anpassen, falls dein Snippet-Storage anders heißt
  node_name    = var.pve_node

  source_raw {
    file_name = "web02-cloudinit.yaml"
    data      = <<-EOT
      #cloud-config
      package_update: true
      packages:
        - qemu-guest-agent
      runcmd:
        - systemctl enable --now qemu-guest-agent
    EOT
  }
}

# VM aus dem Cloud-Init-Template (VM 9000) klonen
resource "proxmox_virtual_environment_vm" "web02" {
  node_name = var.pve_node
  name      = var.name
  vm_id     = var.vmid

  clone {
    vm_id = 9000
  }

  cpu {
    cores = var.cores
  }

  memory {
    dedicated = var.memory
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  disk {
    datastore_id = var.storage # z.B. "local-lvm"
    interface    = "scsi0"
    size         = var.disk_size # Zahl in GiB (z. B. 12)
  }

  initialization {
    user_account {
      username = var.ci_user
      keys     = [var.ssh_public_key]
    }

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    # Snippet mit cloud-init user-data verwenden
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
  }

  agent {
    enabled = true
  }

  vga {
    type = "std"
  }

  boot_order = ["scsi0", "net0"]
}

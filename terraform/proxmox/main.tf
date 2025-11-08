provider "proxmox" {
  endpoint  = var.pm_api_url
  api_token = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  insecure  = true
}

resource "proxmox_virtual_environment_vm" "web02" {
  node_name = var.pve_node
  name      = var.name
  vm_id     = var.vmid

  # aus CI-Template (VM 9000) klonen
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
    datastore_id = var.storage
    interface    = "scsi0"
    size         = var.disk_size # Zahl in GiB
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
  }

  agent {
    enabled = true
  }

  boot_order = ["scsi0", "net0"]
}

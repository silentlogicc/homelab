provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true          # ok im Homelab (self-signed)
}

resource "proxmox_vm_qemu" "web" {
  vmid        = var.vmid
  name        = var.name
  target_node = var.pve_node
  clone       = var.template_name     # -> 9000 / ubuntu-24.04-ci
  full_clone  = true

  # Hardware
  sockets = 1
  cores   = var.cores
  memory  = var.memory

  scsihw = "virtio-scsi-pci"
  boot   = "order=scsi0;net0"

  # Netzwerk
  network {
    model  = "virtio"
    bridge = var.bridge
  }

  # Disk
  disk {
    slot    = 0
    type    = "scsi"
    storage = var.storage
    size    = var.disk_size
  }

  # Cloud-Init: Terraform füttert den Zettel
  ciuser    = var.ci_user
  sshkeys   = var.ssh_public_key
  ipconfig0 = var.ipconfig0
}

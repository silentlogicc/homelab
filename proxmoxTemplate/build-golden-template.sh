#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# This script builds a Proxmox "golden" Ubuntu 24.04 cloud-image VM template.
# It starts searching VMIDs at 9000 and picks the first free one (9000, 9001, ...).
# Every step is explained (in English) above the command, uses sudo, sleeps 5s,
# and prints a small success message.
#
# NOTE about the image:
#   Download the Ubuntu Cloud Image (24.04 "noble") beforehand and place it into
#   a folder named "image" next to this script:
#     noble-server-cloudimg-amd64.img
#   Example (info only): wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
# ─────────────────────────────────────────────────────────────────────────────

# Configurable bits (adjust if your storage names differ)
NAME_PREFIX="ubuntu-cloud"
BRIDGE="vmbr0"
DISK_STORAGE="local-lvm"   # where the VM disk should live (LVM-thin is ideal)
CI_STORAGE="local"         # storage to host the Cloud-Init drive (tutorial style)
MEM_MB=4096                # 4 GiB
CORES=4                    # 4 vCPUs
CI_USER="opsadmin"         # default Cloud-Init username
IMG_PATH="/home/silentlogicc/images/noble-server-cloudimg-amd64.img"
SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPmvNqMJQagcrRIj+NUgioqAgaPntBLvI6/0BYlYHgQD"
CI_PASSWORD=""   # ⚠️ Default-Password; später ändern/entfernen

# Find first free VMID starting at 9000
VMID=9000
while sudo qm status "${VMID}" &>/dev/null; do
  VMID=$((VMID+1))
done
NAME="${NAME_PREFIX}-${VMID}"

echo "→ Selected VMID: ${VMID}  (name: ${NAME})"
sleep 1

# Sanity checks: image file must exist
if [[ ! -f "${IMG_PATH}" ]]; then
  echo "ERROR: Cloud image not found at: ${IMG_PATH}"
  echo "Place 'noble-server-cloudimg-amd64.img' into ./image/ and re-run."
  exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# Create the empty VM shell (no disk yet). We set memory, cores, name and NIC.
# ─────────────────────────────────────────────────────────────────────────────
echo "Creating VM shell ${VMID} (${NAME}) ..."
# Create a new VM with 4 GiB RAM, 4 vCPUs, a virtio NIC on your bridge
sudo qm create "${VMID}" --memory "${MEM_MB}" --cores "${CORES}" --name "${NAME}" --net0 "virtio,bridge=${BRIDGE}"
sleep 5
echo "OK: VM ${VMID} created."

# ─────────────────────────────────────────────────────────────────────────────
# Import the downloaded cloud image as a real VM disk into your storage.
# We import the IMG to DISK_STORAGE (e.g., local-lvm).
# ─────────────────────────────────────────────────────────────────────────────
echo "Importing cloud image into storage ${DISK_STORAGE} ..."
# Import disk (turns the .img into a proper Proxmox disk volume for this VM)
sudo qm importdisk "${VMID}" "${IMG_PATH}" "${DISK_STORAGE}"
sleep 5
echo "OK: Cloud image imported."

# Guess the resulting disk volume name (standard Proxmox naming)
DISK_VOL="${DISK_STORAGE}:vm-${VMID}-disk-0"

# ─────────────────────────────────────────────────────────────────────────────
# Attach the imported disk to the VM as SCSI0 using the virtio-scsi controller.
# virtio-scsi is the modern, performant controller to use with cloud images.
# ─────────────────────────────────────────────────────────────────────────────
echo "Attaching imported disk as scsi0 with virtio-scsi controller ..."
# Set SCSI controller type and attach the disk as scsi0
sudo qm set "${VMID}" --scsihw virtio-scsi-pci --scsi0 "${DISK_VOL}"
sleep 5
echo "OK: Disk attached as scsi0."

# ─────────────────────────────────────────────────────────────────────────────
# Add a Cloud-Init drive (this is the "config CD" the guest reads on first boot).
# We follow the tutorial style and place it on the 'local' storage.
# ─────────────────────────────────────────────────────────────────────────────
echo "Adding Cloud-Init drive on ${CI_STORAGE} ..."
# Add the Cloud-Init drive at ide2 (Proxmox standard slot for CI)
sudo qm set "${VMID}" --ide2 "${CI_STORAGE}:cloudinit"
sleep 5
echo "OK: Cloud-Init drive added."

# ─────────────────────────────────────────────────────────────────────────────
# Ensure the VM boots from the scsi0 disk (the imported cloud image).
# 'boot c' means prefer disk, and bootdisk=scsi0 pins the first disk.
# ─────────────────────────────────────────────────────────────────────────────
echo "Setting boot order to disk (scsi0) ..."
# Make the VM boot from the attached SCSI0 disk
sudo qm set "${VMID}" --boot c --bootdisk scsi0
sleep 5
echo "OK: Boot order set."

# ─────────────────────────────────────────────────────────────────────────────
# Enable a serial console; with cloud images the serial console is handy and
# avoids "black screen" issues in noVNC. 'vga serial0' maps console output.
# ─────────────────────────────────────────────────────────────────────────────
echo "Enabling serial console (serial0) and mapping VGA to serial0 ..."
# Enable serial socket and map VGA to serial0 for reliable console access
sudo qm set "${VMID}" --serial0 socket --vga serial0
sleep 5
echo "OK: Serial console ready."

# ─────────────────────────────────────────────────────────────────────────────
# Turn on the QEMU Guest Agent at the Proxmox side. The guest still needs the
# package 'qemu-guest-agent' installed later inside the VM, but this enables
# the host-side switch so Proxmox can talk to it once installed.
# ─────────────────────────────────────────────────────────────────────────────
echo "Enabling QEMU Guest Agent (host-side flag) ..."
# Enable the guest agent flag so Proxmox expects/uses it when present
sudo qm set "${VMID}" --agent 1
sleep 5
echo "OK: QEMU Guest Agent enabled (host side)."

# ─────────────────────────────────────────────────────────────────────────────
# Seed minimal Cloud-Init values: default username and DHCP for IPv4.
# (SSH key and/or password will be added manually via UI as requested.)
# ─────────────────────────────────────────────────────────────────────────────
echo "Setting Cloud-Init defaults (user=${CI_USER}, IPv4=DHCP, SSH key, password) ..."
# Set username, DHCP for IPv4, Raspberry Pi SSH public key and a default password
# Note: single quotes around the password keep the '!' safe in shells.
echo "Setting Cloud-Init defaults (username + DHCP) ..."
sudo qm set "${VMID}" --ciuser "${CI_USER}" --ipconfig0 "ip=dhcp"
sleep 5
echo "OK: username + dhcp set."

echo "Adding SSH public key ..."
KEYFILE="$(mktemp)"
printf '%s\n' "$SSH_KEY" | sudo tee "$KEYFILE" >/dev/null
sudo qm set "${VMID}" --sshkeys "$KEYFILE"
sudo rm -f "$KEYFILE"
sleep 5
echo "OK: ssh key set."

if [ -n "$CI_PASSWORD" ]; then
  echo "Setting default password ..."
  sudo qm set "${VMID}" --cipassword "${CI_PASSWORD}"
  sleep 5
  echo "OK: password set."
else
  echo "skip: no default password configured."
fi

echo "Regenerating Cloud-Init ISO (this 'burns in' the config) ..."
sudo qm cloudinit update "${VMID}"
sleep 5
echo "OK: cloud-init config applied."

# ─────────────────────────────────────────────────────────────────────────────
# Final info for the operator.
# ─────────────────────────────────────────────────────────────────────────────
echo
echo "────────────────────────────────────────────────────────"
echo "Template base VM prepared: VMID ${VMID}  (name: ${NAME})"
echo "Next steps in Proxmox UI (Cloud-Init tab of VM ${VMID}):"
echo "  1) Add the SSH public key of the device that will SSH in."
echo "  2) (Optional) Set a one-time password if you want password login."
echo "Then: Start the VM once, install 'qemu-guest-agent' inside the guest,"
echo "      shutdown cleanly, and finally 'Convert to template'."
echo "────────────────────────────────────────────────────────"

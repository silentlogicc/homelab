#!/bin/bash
# clone-template.sh — quickly clone a VM from an existing template
# Mode: Full Clone, target storage: local-lvm

# Require root
if [[ $EUID -ne 0 ]]; then
  echo "Please run this script with sudo."
  exit 1
fi

set -e

STORAGE_DEFAULT="local-lvm"

echo "----------------------------------------"
echo " Available VM templates on this node"
echo "----------------------------------------"

TEMPLATE_IDS=()

# alle VM-IDs aus qm list holen (erste Zeile ist Header -> NR>1)
for vmid in $(qm list | awk 'NR>1 {print $1}'); do
  # prüfen, ob diese VM ein Template ist
  if qm config "$vmid" 2>/dev/null | grep -q '^template: 1'; then
    name=$(qm config "$vmid" | awk -F': ' '/^name:/{print $2}')
    TEMPLATE_IDS+=("$vmid")
    printf "  %s  -  %s\n" "$vmid" "$name"
  fi
done

if [ ${#TEMPLATE_IDS[@]} -eq 0 ]; then
  echo "❌ No templates found (no 'template: 1' in qm config)."
  exit 1
fi

echo "----------------------------------------"

# Template auswählen
read -rp "Template VMID to clone: " TEMPLATE_ID

if ! printf '%s\n' "${TEMPLATE_IDS[@]}" | grep -qx "$TEMPLATE_ID"; then
  echo "❌ $TEMPLATE_ID is not in the template list."
  exit 1
fi

# Neue VMID + Name abfragen
read -rp "New VMID: " NEW_VMID
read -rp "New VM name: " NEW_NAME

if qm status "$NEW_VMID" >/dev/null 2>&1; then
  echo "❌ VMID $NEW_VMID already exists. Choose another one."
  exit 1
fi

# Ziel-Storage – aktuell fest auf local-lvm, aber mit Default-Abfrage
read -rp "Target storage [${STORAGE_DEFAULT}]: " STORAGE
STORAGE="${STORAGE:-$STORAGE_DEFAULT}"

echo "----------------------------------------"
echo "Cloning template $TEMPLATE_ID → new VM $NEW_VMID ($NEW_NAME)…"
echo "Mode: Full Clone"
echo "Target storage: $STORAGE"
echo "----------------------------------------"

# Full Clone auf gewünschtes Storage (wie im Proxmox-Dialog)
qm clone "$TEMPLATE_ID" "$NEW_VMID" \
  --name "$NEW_NAME" \
  --full 1 \
  --storage "$STORAGE"

# Onboot einschalten (optional, kannst du rausnehmen wenn du das nicht willst)
qm set "$NEW_VMID" --onboot 1

echo "Clone finished. Trying to start VM…"

if qm start "$NEW_VMID"; then
  echo "✅ VM $NEW_VMID started successfully."
else
  echo "⚠️ VM was cloned, but start failed. Check the Proxmox task log."
fi

echo "----------------------------------------"
qm status "$NEW_VMID"
echo "----------------------------------------"
echo "Done."

#!/bin/bash
# clone-template.sh — quickly clone a VM from an existing template

set -e

echo "----------------------------------------"
echo " Available VM templates on this node"
echo "----------------------------------------"

# Templates finden: in /etc/pve/qemu-server/* nach 'template: 1' suchen
TEMPLATE_IDS=()

for cfg in /etc/pve/qemu-server/*.conf; do
  if grep -q '^template: 1' "$cfg" 2>/dev/null; then
    vmid="${cfg##*/}"
    vmid="${vmid%.conf}"
    name=$(qm config "$vmid" | awk -F': ' '/^name:/{print $2}')
    TEMPLATE_IDS+=("$vmid")
    printf "  %s  -  %s\n" "$vmid" "$name"
  fi
done

if [ ${#TEMPLATE_IDS[@]} -eq 0 ]; then
  echo "❌ No templates found (no 'template: 1' in /etc/pve/qemu-server/*.conf)."
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

echo "----------------------------------------"
echo "Cloning template $TEMPLATE_ID → new VM $NEW_VMID ($NEW_NAME)…"
echo "----------------------------------------"

# Clone ausführen (full clone, gleicher Storage wie Template)
qm clone "$TEMPLATE_ID" "$NEW_VMID" --name "$NEW_NAME" --full 1

# optional ein paar Standard-Settings setzen (kannst du rauswerfen, wenn du willst)
qm set "$NEW_VMID" --onboot 1

# VM starten
qm start "$NEW_VMID"

echo "✅ Done. New VM:"
qm status "$NEW_VMID"

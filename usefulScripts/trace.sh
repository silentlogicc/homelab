#!/bin/bash
# trace.sh — simple traceroute helper (like Windows tracert)

watermark() {
  local GRAY="\e[90m" OFF="\e[0m"
  printf "${GRAY}— powered by silentlogicc — %s ${OFF}\n"
}
# usage:
# watermark

#add this via cmd + r into an existing nano file and add "watermark" to the bottom of the code

#test


# If target is given as argument, use it. Otherwise ask.
TARGET="$1"

if [[ -z "$TARGET" ]]; then
  read -rp "Host or IP to trace (default: 8.8.8.8): " input
  TARGET="${input:-8.8.8.8}"
fi

# Check if traceroute is installed
if ! command -v traceroute >/dev/null 2>&1; then
  echo "⚠️  'traceroute' is not installed."
  echo "   Install it with:"
  echo "   sudo apt install traceroute"
  exit 1
fi

echo "-----------------------------------------------"
echo "Tracing route to: $TARGET"
echo "-----------------------------------------------"

# -n  = no DNS lookup (faster, nur IPs)
# -w2 = 2s Timeout pro Hop
# -q2 = 2 Probes pro Hop (etwas kürzer)
traceroute -n -w 2 -q 2 "$TARGET"

watermark

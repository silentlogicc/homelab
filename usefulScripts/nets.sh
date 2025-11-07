#!/bin/bash

# -----------------------------------------------------------------------------
# nets.sh — compact network overview (IPv4, state, metric) with clean columns
# Idea/Specs: silentlogicc (use cases, layout, colors)
# Implementation assistance: ChatGPT (GPT-5 Thinking) on 2025-11-06
# License: MIT
#
# What it does (in short):
# - Lists network interfaces with: NAME | STATE | IPv4 | METRIC
# - Uses fixed-width columns so headers and rows line up perfectly
# - Colors the STATE cell (green=up, red=down, yellow=other)
# - Greys out IPv4 and METRIC when value is "-" (not present)
# - By default hides virtual/ephemeral interfaces; show them with "-a"
#
# Why the alignment is stable:
# - Each cell is padded to a fixed width *before* any coloring is applied.
# - Then the entire cell (including its trailing spaces) is wrapped in color
#   escape codes. That way ANSI codes never affect the measured width.
#
# Usage:
#   ./nets.sh         # show “real” interfaces (eth*, wlan*, tailscale*)
#   ./nets.sh -a      # show all interfaces (also docker, veth, bridges, lo)
#
# Requirements:
# - Linux with /sys/class/net and the "ip" command (iproute2)
# - Optional: "tput" for portable terminal colors (falls back to ANSI)
#
# Exit codes:
#   0 on success
#   1 on unexpected errors (very unlikely in this simple flow)
# -----------------------------------------------------------------------------

watermark() {
  local GRAY="\e[90m" OFF="\e[0m"
  printf "${GRAY}— powered by silentlogicc — %s ${OFF}\n"
}
# usage:
# watermark


# Whether to show all interfaces (0 = only "real" ifaces; 1 = all ifaces).
SHOW_ALL=0
[ "$1" = "-a" ] && SHOW_ALL=1

# -----------------------------------------------------------------------------
# Colors
# Try to obtain portable terminal capabilities via "tput".
# If tput is not available, fall back to ANSI escape sequences.
# We deliberately keep a small color palette to stay readable everywhere.
# -----------------------------------------------------------------------------
if command -v tput >/dev/null 2>&1; then
  BOLD=$(tput bold)
  RESET=$(tput sgr0)
  GREEN=$(tput setaf 2)
  RED=$(tput setaf 1)
  YELLOW=$(tput setaf 3)
  GRAY=$(tput setaf 7)
  DIM=$(tput dim)
else
  BOLD='\033[1m'
  RESET='\033[0m'
  GREEN='\033[32m'
  RED='\033[31m'
  YELLOW='\033[33m'
  GRAY='\033[37m'
  DIM='\033[2m'
fi

# -----------------------------------------------------------------------------
# Column widths (tune freely; making them wider keeps alignment easy to read)
# Keep these consistent with the header text below.
# -----------------------------------------------------------------------------
W_IF=20      # interface name (e.g., "eth0", "wlan0", "tailscale0")
W_STATE=10   # oper state: "up", "down", "unknown", etc.
W_IP=22      # first IPv4 address in CIDR notation (or "-")
W_METRIC=8   # default-route metric for this interface (or "-")

# -----------------------------------------------------------------------------
# Helper: print a cell left-padded to a fixed width *without* colors.
# We do NOT include color here on purpose. We want the padding to be computed
# solely on printable characters. Coloring (if any) is applied later to the
# fully-padded cell string, so ANSI codes never affect alignment.
# -----------------------------------------------------------------------------
cell() {
  # $1 = text, $2 = width
  # "%-*s" means: left-align in a field of width $2, fill with spaces
  printf "%-*s" "$2" "$1"
}

# -----------------------------------------------------------------------------
# Helper: print the horizontal separator line that exactly matches the table
# widths. We use "+" as column separators to mirror the header row.
# -----------------------------------------------------------------------------
sep() {
  printf "%-*s" "$W_IF" ""     | tr ' ' '-'; printf "+"
  printf "%-*s" "$W_STATE" ""  | tr ' ' '-'; printf "+"
  printf "%-*s" "$W_IP" ""     | tr ' ' '-'; printf "+"
  printf "%-*s\n" "$W_METRIC" "" | tr ' ' '-'
}

# -----------------------------------------------------------------------------
# Header row (bold). We first build padded cells (plain text), then wrap them
# with BOLD/RESET. Because padding is already done, coloring won’t shift columns.
# -----------------------------------------------------------------------------
h1=$(cell "IFACE"  "$W_IF")
h2=$(cell "STATE"  "$W_STATE")
h3=$(cell "IPV4"   "$W_IP")
h4=$(cell "METRIC" "$W_METRIC")
printf "%s|%s|%s|%s\n" "${BOLD}${h1}${RESET}" "${BOLD}${h2}${RESET}" "${BOLD}${h3}${RESET}" "${BOLD}${h4}${RESET}"
sep

# -----------------------------------------------------------------------------
# Data rows
# For each interface under /sys/class/net:
#   - Optionally skip virtual/transient ifaces unless "-a" was passed
#   - Read operstate
#   - Get first IPv4 address (if any)
#   - Derive the default-route metric for this device (lowest metric if many)
#   - Build padded cells without color, then color the STATE/empty values
#   - Print the row
# -----------------------------------------------------------------------------
for devpath in /sys/class/net/*; do
  i=$(basename "$devpath")

  # Skip virtual/ephemeral interfaces by default to keep the list compact.
  # Pass -a to show everything, including loopback, docker bridges, veth, etc.
  if [ $SHOW_ALL -eq 0 ]; then
    case "$i" in
      lo|docker*|veth*|br-*|br[0-9a-f]*|virbr*|tap*|vmnet*)
        continue
        ;;
    esac
  fi

  # Interface state from sysfs; fallback to "unknown" if unreadable.
  state=$(cat "/sys/class/net/$i/operstate" 2>/dev/null || echo unknown)

  # First IPv4 (CIDR) for this interface; if none -> "-"
  ipv4=$(ip -4 -o addr show dev "$i" 2>/dev/null | awk '{print $4}' | head -n1)
  [ -z "$ipv4" ] && ipv4="-"

  # Default-route metric for this interface:
  #   - Look at "ip route show default dev <iface>"
  #   - Find "metric <N>" tokens; sort numerically; pick the lowest
  # If no default route via this iface exists -> "-"
  metric=$(
    ip route show default dev "$i" 2>/dev/null \
      | awk '{for (j=1; j<=NF; j++) if ($j=="metric") print $(j+1)}' \
      | sort -n | head -n1
  )
  [ -z "$metric" ] && metric="-"

  # Build padded cells (plain, uncolored)
  c_if=$(cell "$i"       "$W_IF")
  c_state=$(cell "$state" "$W_STATE")
  c_ip=$(cell "$ipv4"    "$W_IP")
  c_metric=$(cell "$metric" "$W_METRIC")

  # Color the fully padded STATE cell (entire cell gets the color).
  # This guarantees that ANSI sequences never change the visual width.
  case "$state" in
    up)     c_state="${GREEN}${c_state}${RESET}" ;;
    down)   c_state="${RED}${c_state}${RESET}" ;;
    *)      c_state="${YELLOW}${c_state}${RESET}" ;;
  esac

  # Dim/grey placeholder dashes so missing values are visually subtle.
  [ "$ipv4" = "-" ]   && c_ip="${DIM}${GRAY}${c_ip}${RESET}"
  [ "$metric" = "-" ] && c_metric="${DIM}${GRAY}${c_metric}${RESET}"

  # Print the final row. Cells are already padded; "|" is a visual separator.
  printf "%s|%s|%s|%s\n" "$c_if" "$c_state" "$c_ip" "$c_metric"
done

echo
watermark

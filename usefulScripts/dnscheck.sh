#!/bin/bash
# dnscheck.sh — simple DNS lookup helper

YELLOW=$'\e[33m'
GREEN=$'\e[32m'
RED=$'\e[31m'
CYAN=$'\e[36m'
OFF=$'\e[0m'

# Target: from argument or ask
TARGET="$1"
if [[ -z "$TARGET" ]]; then
  read -rp "Hostname to resolve: " input
  TARGET="${input:-heise.de}"
fi

echo "----------------------------------------"
echo -e "${CYAN}Resolving:${OFF} $TARGET"
echo "----------------------------------------"

# If dig is installed, use it for IP + lookup time
if command -v dig >/dev/null 2>&1; then
  OUT=$(dig +short +stats "$TARGET")

  IP=$(grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' <<< "$OUT" | head -n1)
  QTIME=$(grep -Eo 'Query time: [0-9]+' <<< "$OUT" | awk '{print $3}')

  if [[ -n "$IP" ]]; then
    echo "IP: $IP"
    [[ -n "$QTIME" ]] && echo "Lookup time: ${QTIME} ms"
    echo -e "DNS is ${GREEN}OK ✔${OFF}"
    exit 0
  else
    echo -e "${RED}No IPv4 A record found.${OFF}"
    exit 1
  fi
else
  # Fallback ohne dig: getent hosts
  if getent hosts "$TARGET" >/dev/null 2>&1; then
    IP=$(getent hosts "$TARGET" | awk '{print $1}' | head -n1)
    echo "IP: $IP"
    echo -e "DNS is ${GREEN}OK ✔${OFF} (via getent, no timing)"
    exit 0
  else
    echo -e "${RED}DNS lookup failed.${OFF}"
    exit 1
  fi
fi

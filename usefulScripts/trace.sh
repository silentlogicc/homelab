#!/bin/bash

# trace.sh — show route to a host with geo info and quality rating

# Colors
# Colors (using $'' so \e wird als ESC interpretiert)
CYAN=$'\e[36m'
YELLOW=$'\e[33m'
GREEN=$'\e[32m'
RED=$'\e[31m'
GRAY=$'\e[90m'
OFF=$'\e[0m'

# Ask for target
echo -n "Host or IP to trace (default: 8.8.8.8): "
read TARGET
TARGET=${TARGET:-8.8.8.8}

echo "-----------------------------------------------"
echo -e "${CYAN}Tracing route to:${OFF} $TARGET"
echo "-----------------------------------------------"

# Run traceroute (numeric IPs, default params)
OUTPUT=$(traceroute -n "$TARGET" 2>/dev/null)

# Counters for summary
TOTAL_HOPS=0
FASTEST_MS=999999
FASTEST_HOP="-"
SLOWEST_MS=0
SLOWEST_HOP="-"
TIMEOUT_HOPS=0

# Print header line from traceroute
# (first line: 'traceroute to ...')
echo "$OUTPUT" | head -n1

# Process hop lines (skip first line)
while IFS= read -r line; do
    # Example line:
    # 1  192.168.2.1  0.930 ms  1.057 ms
    # or with timeouts:
    # 4  * * *

    # If line is empty, skip
    [[ -z "$line" ]] && continue

    HOP_NUM=$(echo "$line" | awk '{print $1}')
    IP=$(echo "$line" | awk '{print $2}')

    # If first "IP" is *, this hop gave no response
    if [[ "$IP" == "*" ]]; then
        TIMEOUT_HOPS=$((TIMEOUT_HOPS + 1))
        echo -e "${YELLOW}$(printf '%-3s' "$HOP_NUM") * * *  ${GRAY}(no response)${OFF}"
        continue
    fi

    # Extract first latency value
    LAT=$(echo "$line" | grep -o "[0-9.]* ms" | head -n1 | awk '{print $1}')
    LAT_INT=${LAT%.*}

    # Geo info (country etc.)
    GEO=$(geoiplookup "$IP" 2>/dev/null | awk -F ": " '{print $2}')
    [[ -z "$GEO" ]] && GEO="Unknown"

    TOTAL_HOPS=$((TOTAL_HOPS + 1))

    # Track fastest / slowest
    if (( LAT_INT < FASTEST_MS )); then
        FASTEST_MS=$LAT_INT
        FASTEST_HOP="$HOP_NUM ($IP)"
    fi
    if (( LAT_INT > SLOWEST_MS )); then
        SLOWEST_MS=$LAT_INT
        SLOWEST_HOP="$HOP_NUM ($IP)"
    fi

    # Print hop line
    printf "%-3s %-15s %-8s  %s\n" \
        "$HOP_NUM" "$IP" "${LAT}ms" "${GRAY}[$GEO]${OFF}"
done <<< "$(echo "$OUTPUT" | tail -n +2)"

# Decide route quality
QUALITY_TEXT="GOOD"
QUALITY_COLOR="$GREEN"

# simple rule: timeouts or very slow hops -> POOR
if (( TIMEOUT_HOPS > 0 )) || (( SLOWEST_MS > 150 )); then
    QUALITY_TEXT="POOR"
    QUALITY_COLOR="$RED"
fi

echo "-----------------------------------------------"
echo -e "${CYAN}Route summary${OFF}"
echo "-----------------------------------------------"
echo "Target: $TARGET"
echo "Total hops (with response): $TOTAL_HOPS"
echo "Timeout hops (no response): $TIMEOUT_HOPS"
echo "Fastest hop: $FASTEST_HOP (${FASTEST_MS} ms)"
echo "Slowest hop: $SLOWEST_HOP (${SLOWEST_MS} ms)"
echo -e "Route quality: ${QUALITY_COLOR}${QUALITY_TEXT}${OFF}"
echo "-----------------------------------------------"
echo -e "${GRAY}— powered by silentlogicc —${OFF}"

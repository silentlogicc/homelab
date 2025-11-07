#!/bin/bash
# prints local network information (single line per key) in a simple table

# requirements:
#   - ip command (usually installed by default)

watermark() {
  local GRAY="\e[90m" OFF="\e[0m"
  printf "${GRAY}— powered by silentlogicc — %s${OFF}\n"
}
# usage:
# watermark

##################################### Skript start ##############################################

# color codes (for nicer value output)
CYAN="\e[36m"
OFF="\e[0m"

# get default interface (the one used for the default route)
iface=$(ip route | awk '/^default/ {print $5; exit}')

# get default gateway (next hop for default route)
gateway=$(ip route | awk '/^default/ {print $3; exit}')

# get primary IPv4 with prefix (e.g. 192.168.2.179/24)
ipv4_cidr=$(ip -4 -o addr show dev "$iface" scope global | awk '{print $4; exit}')
ipv4=$(echo "$ipv4_cidr" | cut -d/ -f1)    # only IPv4 address
prefix=$(echo "$ipv4_cidr" | cut -d/ -f2)  # prefix number (e.g. 24)

# calculate netmask from prefix (pure Bash, no ipcalc needed)
# turns e.g. /24 into 255.255.255.0
if [ -n "$prefix" ]; then
  mask=$(( (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF ))
  netmask=$(printf "%d.%d.%d.%d" \
    $(( (mask >> 24) & 255 )) \
    $(( (mask >> 16) & 255 )) \
    $(( (mask >> 8)  & 255 )) \
    $((  mask        & 255 )))
else
  netmask="-"
fi

# get connected IPv4 network (e.g. 192.168.2.0)
subnet_cidr=$(ip -4 route show dev "$iface" scope link | awk '/proto kernel/ {print $1; exit}')
subnet=$(echo "$subnet_cidr" | cut -d/ -f1)

# get IPv6 (may be empty)
ipv6_cidr=$(ip -6 -o addr show dev "$iface" scope global | awk '{print $4; exit}')

# collect DNS servers
dns=$(awk '/^nameserver/ {print $2}' /etc/resolv.conf | paste -sd',' -)

# output
echo "-----------------------------------------------"
printf "%-10s | %s\n" "IFACE" "$iface"
echo "-----------------------------------------------"

printf "%-10s | ${CYAN}%s${OFF}\n" "IPv4"     "$ipv4"
printf "%-10s | ${CYAN}%s${OFF}\n" "Netmask"  "$netmask"
printf "%-10s | ${CYAN}%s${OFF}\n" "Subnet"   "$subnet"
printf "%-10s | ${CYAN}%s${OFF}\n" "Prefix"   "$prefix"
printf "%-10s | ${CYAN}%s${OFF}\n" "IPv6"     "$ipv6_cidr"
printf "%-10s | ${CYAN}%s${OFF}\n" "Gateway"  "$gateway"
printf "%-10s | ${CYAN}%s${OFF}\n" "DNS"      "$dns"

echo "-----------------------------------------------"
printf "%-10s | %s\n" "Checked" "$(date '+%Y-%m-%d %H:%M:%S')"
echo "-----------------------------------------------"

watermark

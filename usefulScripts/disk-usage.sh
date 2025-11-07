#!/bin/bash

watermark() {
  local GRAY="\e[90m" OFF="\e[0m"
  printf "${GRAY}— powered by silentlogicc — %s ${OFF}\n"
}
# usage:
# watermark

# prints first IP only
ip=$(hostname -I | awk '{print $1}')

# prints system hostname
host="$(hostname)"

# reads the 2nd line of df output and extracts the percentage
usage=$(df -hP / | awk 'NR==2 {print $5}')

# shows how much free space is left (4th column)
free=$(df -hP / | awk 'NR==2 {print $4}')

# shows how many inodes are free
inodes=$(df -i / | awk 'NR==2 {print $4}')

# removes the "%" sign from usage (example: "21%" becomes "21")
num=${usage%\%}

#add top-bottom separator lines to format output 
echo "------------------------------------"

# formatted output (aligned columns)
printf "%-15s %s\n" "ip:" "$ip"
printf "%-15s %s\n" "hostname:" "$host"
printf "%-15s %s\n" "usage:" "$usage"
printf "%-15s %s\n" "free space:" "$free"
printf "%-15s %s\n" "free inodes:" "$inodes"
printf "%-15s %s\n" "checked at:" "$(date '+%Y-%m-%d %H:%M:%S')"

echo "------------------------------------"

# compares the number with 85 (if usage >= 85 → print warning)
if [ "$num" -ge 85 ]; then
  printf "%-15s %s\n" "warning:" "disk usage is high!"
fi

watermark

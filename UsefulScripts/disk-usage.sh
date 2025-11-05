#!/bin/bash

# prints system hostname
echo "hostname: $(hostname)"

# prints system IPv4
hostname -I | awk '{print $1}'

# prints timestamp when the script was executed
echo "checked at $(date)"

# reads the 2nd line of df output and extracts the percentage
usage=$(df -hP / | awk 'NR==2 {print $5}')
echo "disk usage is $usage"

# shows how much free space is left (4th column)
free=$(df -hP / | awk 'NR==2 {print $4}')
echo "free space is $free"

# shows how many inodes are free
inodes=$(df -i / | awk 'NR==2 {print $4}')
echo "free inodes: $inodes"

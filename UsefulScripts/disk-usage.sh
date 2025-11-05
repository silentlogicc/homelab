#!/bin/bash

#shows disk usage in a human readable format

#df -h /

#prints timestamp when the script was executed

echo "checked at $(date)"

# reads the 2nd line of df output and extracts the percentage

usage=$(df -h / | awk 'NR==2 {print $5}')
echo "disk usage is $usage"

# shows how much free space is left (4th column)
free=$(df -hP / | awk 'NR==2{print $4}')
echo "free space is $free"

inodes=$(df -i / | awk 'NR==2{print $4}')
echo "free inodes: $inodes"

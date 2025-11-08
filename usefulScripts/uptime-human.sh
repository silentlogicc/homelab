#!/bin/bash
# show human readable uptime using python

upt_sec=$(cat /proc/uptime | awk '{print int($1)}')

python3 - <<EOF
sec = $upt_sec
d = sec // 86400
h = (sec % 86400) // 3600
m = (sec % 3600) // 60
print(f"{d}d {h}h {m}m total uptime")
EOF

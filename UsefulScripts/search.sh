#!/bin/bash

# asks for a simple name and searches from the current directory (.)
# no path prompt, no case options, no grep — just basic find

read -r -p "Search term (name fragment): " term
if [ -z "$term" ]; then
  echo "No term provided. Exiting."
  exit 1
fi

echo "What do you want to search?"
echo "  1) files"
echo "  2) directories"
read -r -p "Choose 1 or 2: " choice

case "$choice" in
  1)
    # files by name (case-insensitive), search from current dir
    find / -type f -iname "*$term*" 2>/dev/null
    ;;
  2)
    # directories by name (case-insensitive)
    find / -type d -iname "*$term*" 2>/dev/null
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

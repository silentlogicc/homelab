#!/bin/bash
# make-all-exec.sh — macht alle regulären Dateien in einem Ordner ausführbar
# usage: make-all-exec.sh /path/to/dir
DIR="${1:-"$HOME/homelab/usefulScripts"}"

if [ ! -d "$DIR" ]; then
  echo "Directory not found: $DIR" >&2
  exit 1
fi

for f in "$DIR"/*.sh "$DIR"/*.py ; do
  [ -f "$f" ] || continue
  sudo chmod +x -- "$f" && echo "chmod +x $f"
done

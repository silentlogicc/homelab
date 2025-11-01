#!/usr/bin/env bash

echo "Script läuft auf: $(hostname)"
echo "Zeit: $(date)"

# zeigt menschlich lesbare RAM werte
# -h = human readable (GB / MB etc.)

free -h

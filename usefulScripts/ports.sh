#!/bin/bash
# portsv4.sh — listening sockets mit minimalistischen Farben, perfekt ausgerichtet (links)

# this script has been created with AI help

# needs root for full process info
if [[ $EUID -ne 0 ]]; then
  exec sudo -E "$0" "$@"
fi

watermark() {
  local GRAY="\e[90m" OFF="\e[0m"
  printf "${GRAY}— powered by silentlogicc — %s ${OFF}\n"
}
# usage:
# watermark


# --- Farben ---
BOLD=$'\e[1m'; OFF=$'\e[0m'
CYAN=$'\e[36m'; GREEN=$'\e[32m'
RED=$'\e[31m'; GRAY=$'\e[90m'; YELLOW=$'\e[33m'
WHITE=$'\e[37m'

# Spaltenbreiten
W_PROTO=6; W_LOCAL=42; W_PORT=8; W_STATE=10; W_PID=8; W_PS=36

# --- Port -> Service Map (optional, erweiterbar) ---
declare -A PORT_MAP=(
  [22]="ssh" [80]="http" [443]="https"
  [3000]="grafana" [8080]="http-alt" [8000]="dev-http"
  [5000]="flask" [3306]="mysql" [5432]="postgres"
  [27017]="mongodb" [5601]="kibana" [631]="ipp"
)

# ss-Ausgabe (mit Prozessen)
ss_out=$(ss -H -tunlp 2>/dev/null) || {
  echo "Need root for process info — retry with sudo..."
  ss_out=$(sudo ss -H -tunlp 2>/dev/null) || { echo "ss failed."; exit 1; }
}

# --- Überschrift (türkis) + Leerzeile ---
echo "${CYAN}Listening sockets${OFF}"
echo

# --- Header (weiß), feste Breiten ---
printf "%-6s | %-42s | %-8s | %-10s | %-8s | %-36s\n" \
  "PROTO" "LOCAL" "PORT" "STATE" "PID" "PROGRAM/SERVICE"

# Linie exakt passend: 6 + 3 + 42 + 3 + 8 + 3 + 10 + 3 + 8 + 3 + 36 = 125
printf '%*s\n' 125 '' | tr ' ' '-'

# Helper: farbige Spalte drucken (Farben außerhalb des Platzhalters!)
print_col() {
  local width="$1" color="$2" text="$3"
  printf "%s" "$color"
  printf "%-${width}s" "$text"
  printf "%s" "$OFF"
}

# Helper: Program/Service farbig + korrekt gepaddet (türkis + grau)
print_ps() {
  local width="$1" prog="$2" service="$3"
  local plain
  if [[ "$prog" == "-" && "$service" == "-" ]]; then
    # fehlend -> roter Gedankenstrich
    plain="-"
    printf "%s" "$RED"
    printf "%-${width}s" "$plain"
    printf "%s" "$OFF"
    return
  fi
  if [[ "$service" != "-" ]]; then
    plain="${prog} (${service})"
  else
    plain="${prog}"
  fi
  # Sichtbare Länge (ohne Farbcodes) für Padding
  local vis_len=${#plain}
  (( vis_len < width )) && pad=$((width - vis_len)) || pad=0

  # jetzt farbig ausgeben, danach Leerzeichen für Padding
  if [[ "$service" != "-" ]]; then
    printf "%s%s%s (%s%s%s)%*s" \
      "$CYAN" "$prog" "$OFF" \
      "$GRAY" "$service" "$OFF" \
      "$pad" ""
  else
    printf "%s%s%s%*s" "$CYAN" "$prog" "$OFF" "$pad" ""
  fi
}

# Helper: roter Gedankenstrich-Text (als Klartext für Breite)
dash="-"

# Zeilen parsen
while IFS= read -r line; do
  row=$(echo "$line" | tr -s ' ')

  proto=$(awk '{print $1}' <<<"$row")
  state=$(awk '{print $2}' <<<"$row")
  localcol=$(awk '{print $5}' <<<"$row")
  local_host="${localcol%:*}"
  port="${localcol##*:}"

  pid="-" ; prog="-"

  # Prozessinfo extrahieren
  proc_field=$(awk '{for (i=1;i<=NF;i++) if ($i ~ /^users:/) {for (j=i;j<=NF;j++) printf $j" "; print ""; break}}' <<<"$row")
  if [[ -n "$proc_field" ]]; then
    [[ $proc_field =~ \"([^\"]+)\" ]] && prog="${BASH_REMATCH[1]}"
    if [[ $proc_field =~ pid=([0-9]+) ]]; then pid="${BASH_REMATCH[1]}"; fi
  fi

  # Service ableiten
  service="-"
  if [[ -n "${PORT_MAP[$port]:-}" ]]; then
    service="${PORT_MAP[$port]}"
  else
    svc=$(getent services "${port}"/tcp 2>/dev/null | awk '{print $1}' | head -n1)
    [[ -n "$svc" ]] && service="$svc"
  fi

  # --- Inhalte je Spalte (nur Klartext in printf, Farben außenrum) ---
  # PROTO: immer weiß; fehlend -> roter Strich
  txt_proto="$proto"
  col_proto="$WHITE"
  [[ -z "$txt_proto" || "$txt_proto" == "-" ]] && { txt_proto="$dash"; col_proto="$RED"; }

  # LOCAL: weiß; loopback grau; '*' gelb; fehlend rot
  txt_local="$local_host"
  if [[ -z "$txt_local" || "$txt_local" == "-" ]]; then
    txt_local="$dash"; col_local="$RED"
  elif [[ "$txt_local" == "127.0.0.1" || "$txt_local" == "[::1]" ]]; then
    col_local="$GRAY"
  elif [[ "$txt_local" == "*" ]]; then
    col_local="$YELLOW"
  else
    col_local="$WHITE"
  fi

  # PORT: türkis; fehlend rot
  txt_port="$port"; col_port="$CYAN"
  [[ -z "$txt_port" || "$txt_port" == "-" ]] && { txt_port="$dash"; col_port="$RED"; }

  # STATE: LISTEN grün; UNKNOWN/UNCONN/sonst weiß; fehlend -> roter Strich
  if [[ -z "$state" || "$state" == "-" ]]; then
    txt_state="$dash"; col_state="$RED"
  elif [[ "$state" == "LISTEN" ]]; then
    txt_state="$state"; col_state="$GREEN"
  elif [[ "$state" == "UNKNOWN" || "$state" == "UNCONN" ]]; then
    txt_state="$state"; col_state="$WHITE"
  else
    txt_state="$state"; col_state="$WHITE"
  fi

  # PID: Zahl weiß; fehlend -> roter Strich
  if [[ "$pid" =~ ^[0-9]+$ ]]; then
    txt_pid="$pid"; col_pid="$WHITE"
  else
    txt_pid="$dash"; col_pid="$RED"
  fi

  # PROGRAM/SERVICE vorbereitet (plain)
  ps_prog="$prog"
  ps_service="$service"
  if [[ "$ps_prog" == "-" && "$ps_service" == "-" ]]; then
    ps_prog="-"; ps_service="-"
  fi

  # Ausgabe: jede Spalte separat formatieren, Farben außenrum
  print_col "$W_PROTO" "$col_proto" "$txt_proto"; printf " | "
  print_col "$W_LOCAL" "$col_local" "$txt_local"; printf " | "
  print_col "$W_PORT"  "$col_port"  "$txt_port";  printf " | "
  print_col "$W_STATE" "$col_state" "$txt_state"; printf " | "
  print_col "$W_PID"   "$col_pid"   "$txt_pid";   printf " | "
  print_ps  "$W_PS" "$ps_prog" "$ps_service"
  printf "\n"

done <<< "$ss_out"

watermark

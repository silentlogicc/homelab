#!/bin/bash
# Setup-Script für web01 (Ubuntu Server + Apache + Zabbix-Agent)

set -e

### ===== VARIABLEN ANPASSEN =====
ZBX_SERVER_IP="192.168.2.198"   # IP deines Zabbix-Servers
HOSTNAME_NEW="web01"            # Hostname dieser VM
HTML_TEXT="web01 – Testseite für Monitoring"
### ==============================


echo "==> Hostname setzen auf ${HOSTNAME_NEW}"
sudo hostnamectl set-hostname "${HOSTNAME_NEW}"

echo "==> System aktualisieren"
sudo apt update && sudo apt upgrade -y

echo "==> Apache Webserver installieren"
sudo apt install -y apache2

echo "==> Apache beim Booten aktivieren"
sudo systemctl enable --now apache2

echo "==> Einfache Test-HTML-Seite anlegen"
echo "<h1>${HTML_TEXT}</h1>" | sudo tee /var/www/html/index.html >/dev/null

echo "==> Zabbix-Repository hinzufügen"
wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-1+ubuntu$(lsb_release -rs)_all.deb -O /tmp/zabbix-release.deb
sudo dpkg -i /tmp/zabbix-release.deb
sudo apt update

echo "==> Zabbix-Agent installieren"
sudo apt install -y zabbix-agent

echo "==> Zabbix-Agent konfigurieren"
ZBX_CONF="/etc/zabbix/zabbix_agentd.conf"

# Backup der Originaldatei
if [ ! -f "${ZBX_CONF}.bak" ]; then
  sudo cp "${ZBX_CONF}" "${ZBX_CONF}.bak"
fi

sudo bash -c "cat >> ${ZBX_CONF} <<EOF

### --- Custom config (automatisch gesetzt) ---
Server=${ZBX_SERVER_IP}
ServerActive=${ZBX_SERVER_IP}
Hostname=${HOSTNAME_NEW}
### --- Ende Custom config ---
EOF"

echo "==> Zabbix-Agent neu starten und aktivieren"
sudo systemctl restart zabbix-agent
sudo systemctl enable zabbix-agent

echo "==> Fertig! Apache läuft, Testseite aktiv, Agent verbunden."
echo "==> Jetzt im Zabbix-WebUI Host '${HOSTNAME_NEW}' anlegen."

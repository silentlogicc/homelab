#!/bin/bash
# Zabbix 7 + MariaDB + Apache + Web-UI Autoinstall
# Für frisches Ubuntu (als root ausführen)

set -e

# ==== HIER DEIN EIGENES DB-PASSWORT EINTRAGEN ====
ZBX_DB_PASS="MegaSicheresPasswort123!"
# ================================================

if [[ $EUID -ne 0 ]]; then
 echo "Bitte als root ausführen (sudo -i)."
 exit 1
fi

echo "==> System aktualisieren..."
apt update && apt -y upgrade

echo "==> Apache, MariaDB, PHP installieren..."
apt install -y apache2 mariadb-server php php-mbstring php-mysql libapache2-mod-php wget

echo "==> Zabbix-Repository hinzufügen..."
UBU_VER=$(lsb_release -rs)
wget -O /tmp/zabbix-release.deb \
 "https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_7.0-1+ubuntu${UBU_VER}_all.deb"
dpkg -i /tmp/zabbix-release.deb
apt update

echo "==> Zabbix-Server, Frontend und Agent installieren..."
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

echo "==> MariaDB: Datenbank und Benutzer 'zabbix' anlegen..."
mariadb <<EOF
DROP DATABASE IF EXISTS zabbix;
DROP USER IF EXISTS 'zabbix'@'localhost';
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '${ZBX_DB_PASS}';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "==> Zabbix-Schema in die Datenbank importieren..."
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | \
 mysql -u zabbix -p"${ZBX_DB_PASS}" zabbix

echo "==> Zabbix-Server-Konfiguration anpassen..."
# Falls DBPassword auskommentiert ist:
sed -i "s/^# DBPassword=.*/DBPassword=${ZBX_DB_PASS}/" /etc/zabbix/zabbix_server.conf || true
# Falls DBPassword noch gar nicht existiert:
grep -q "^DBPassword=" /etc/zabbix/zabbix_server.conf || \
 echo "DBPassword=${ZBX_DB_PASS}" >> /etc/zabbix/zabbix_server.conf

echo "==> Dienste starten und aktivieren..."
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache2

IP=$(hostname -I | awk '{print $1}')
echo "===================================================="
echo "FERTIG!"
echo "Zabbix-Web UI:   http://$IP/zabbix"
echo "Login:           Admin / zabbix"
echo "DB-Name:         zabbix"
echo "DB-User:         zabbix"
echo "DB-Passwort:     ${ZBX_DB_PASS}"
echo "===================================================="

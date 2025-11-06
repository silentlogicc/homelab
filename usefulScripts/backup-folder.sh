#!/bin/bash

# liest das erste Argument (der Ordnerpfad der gesichert werden soll)
ordner="$1"

# erstellt einen Dateinamen mit dem aktuellen Datum
filename="backup_$(date +%Y-%m-%d).tar.gz"

# erzeugt ein komprimiertes tar Archiv aus dem angegebenen Ordner
# -c = create / -z = gzip komprimieren / -f = Dateiname setzen
tar -czf "$filename" "$ordner"

# prüft ob der Zielordner existiert
# wenn nicht → wird er erstellt
if [ ! -d /home/skatefreak3/backups/ ]; then
    mkdir -p /home/skatefreak3/backups/
fi

# verschiebt die Archivdatei in den Zielordner
mv "$filename" /home/skatefreak3/backups/

# überprüft ob der letzte Befehl erfolgreich war
# 0 = erfolgreich / alles andere = Fehler
if [ $? -eq 0 ]; then
    echo "Success"
else
    echo "Error "
fi

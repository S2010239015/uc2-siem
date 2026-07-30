#!/usr/bin/env bash
# Szenario 2 - Insider / Living-off-the-Land
# Kein Fremd-Tooling. Missbrauch legitimer Bordmittel nach erlangtem
# Zugang. Hier trennt sich die Erkennungsqualität der beiden SIEMs.
#
# GERÜST - die konkreten Schritte werden gemeinsam beim Durchgang
# durch die 11 Ground-Truth-Events festgelegt. Geplante Bausteine:
#   E?  - Anmeldung mit erbeutetem Konto (sysops)
#   E?  - Rechteausweitung über sudo
#   E?  - Download einer Nutzlast per curl (kein Malware-Signatur-Hit)
#   E?  - Persistenz über cron oder systemd-Timer
#   E?  - Auslesen von /etc/shadow
#
# Ausführung erfolgt teils auf dem victim selbst. Dieses Skript
# stösst die Schritte per SSH an und protokolliert Zeitstempel,
# damit die Events später sauber zugeordnet werden können.
set -euo pipefail

VICTIM="${VICTIM_IP:-192.168.20.20}"

echo "[*] Szenario 2 - Start: $(date --iso-8601=seconds)"
echo "[!] TODO: Schritte nach Festlegung der Event-Zuordnung einfügen."
echo "[*] Szenario 2 - Ende: $(date --iso-8601=seconds)"

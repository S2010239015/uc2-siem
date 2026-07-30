#!/usr/bin/env bash
# Wazuh All-in-One auf dem siem-Host. Im Betrieb ausfuehren:
#   sudo /opt/siem/install-wazuh-manager.sh
# Richtet Swap und vm.max_map_count ein und installiert Manager,
# Indexer und Dashboard. Danach den Agent auf victim installieren.
set -euo pipefail

echo "[*] Swap einrichten (Pflicht, sonst OOM-Killer)"
if ! swapon --show | grep -q '/swapfile'; then
  fallocate -l 4G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

echo "[*] vm.max_map_count fuer den Indexer setzen"
echo 'vm.max_map_count=262144' > /etc/sysctl.d/99-siem.conf
sysctl --system >/dev/null

echo "[*] Wazuh installieren"
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh
bash ./wazuh-install.sh -a --ignore-check

echo "[+] Fertig. Das Admin-Passwort steht oben in der Zusammenfassung."
echo "    Naechster Schritt: auf victim sudo /opt/siem/install-wazuh-agent.sh 192.168.20.20"

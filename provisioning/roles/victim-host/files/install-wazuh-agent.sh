#!/usr/bin/env bash
# Wazuh-Agent auf victim. Im Betrieb ausfuehren, nachdem der Manager
# auf siem laeuft:
#   sudo /opt/siem/install-wazuh-agent.sh 192.168.20.20
set -euo pipefail

MANAGER="${1:-192.168.20.20}"

echo "[*] Wazuh-Repository einrichten (Pfad 4.x, signed-by fuer Noble)"
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH \
  | gpg --batch --yes --dearmor -o /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
  > /etc/apt/sources.list.d/wazuh.list
apt-get update

echo "[*] Wazuh-Agent installieren, Manager: ${MANAGER}"
WAZUH_MANAGER="${MANAGER}" WAZUH_AGENT_NAME="victim" apt-get install -y wazuh-agent

systemctl daemon-reload
systemctl enable --now wazuh-agent
echo "[+] Agent laeuft. Kontrolle auf siem: sudo /var/ossec/bin/agent_control -l"

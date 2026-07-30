# UC2 -- SIEM-Vergleich (Wazuh vs. Elastic)

Sandbox-Definition fuer Use Case 2. Die Definition beschreibt eine
**neutrale Umgebung** -- das SIEM ist nicht Teil der Sandbox, sondern
wird nach der Allokation im Betrieb installiert. So bleibt die Umgebung
tool-unabhaengig und reproduzierbar.

## Topologie

Ein Netz `lab-switch` (192.168.20.0/24), analog zu UC1.

| Host     | IP             | Flavor         | Inhalt                       |
|----------|----------------|----------------|------------------------------|
| siem     | 192.168.20.20  | m1.large       | leerer Host + Install-Skripte |
| victim   | 192.168.20.5   | m1.small       | Web, DB, geplante Schwaechen  |
| attacker | 192.168.20.30  | m1.small       | Werkzeuge, Rauschen, Szenarien |
| router   | 192.168.20.1   | standard.small | Gateway                      |

## Was das Provisioning macht

Ausschliesslich die neutrale Umgebung:

- **victim**: Apache + PHP + MySQL (DB `firma`), schwacher User `sysops`,
  NOPASSWD-sudo, SUID auf find/vim, auditd-Regeln, DB-Zugangsdaten als
  auffindbare Spur. Kein SIEM-Agent.
- **attacker**: nmap, hydra, sshpass, mysql-client, die drei
  Szenario-Skripte unter `/opt/scenarios/` und ein Traffic-Generator
  (`traffic-noise.service`), der Normal-Traffic gegen victim erzeugt.
- **siem**: leerer Host. Nur die Install-Skripte werden unter
  `/opt/siem/` abgelegt, aber nicht ausgefuehrt.

## SIEM im Betrieb installieren

Nach der Allokation, ueber die Management-SSH-Config:

Auf siem (Manager, Indexer, Dashboard, plus Swap und sysctl):
```
sudo /opt/siem/install-wazuh-manager.sh
```

Danach auf victim (Agent, zeigt auf den Manager):
```
sudo /opt/siem/install-wazuh-agent.sh 192.168.20.20
```

Kontrolle auf siem:
```
sudo /var/ossec/bin/agent_control -l
```

Fuer den Elastic-Lauf: neutrale Umgebung frisch allokieren und die
Elastic-Skripte ausfuehren (folgen nach dem Wazuh-Durchlauf). Weil jeder
Lauf auf einem frischen Host startet, gibt es keine Restzustaende
zwischen den beiden SIEMs.

## Szenarien ausfuehren

Vom attacker, in Reihenfolge:
```
/opt/scenarios/scenario1_baseline.sh
/opt/scenarios/scenario2_lotl.sh
/opt/scenarios/scenario3_lateral.sh
```

Die 11 Ground-Truth-Events und die Metriken stehen in
`docs/ground-truth-events.md`.

## Offen

- Erkennungskriterium pro Event (Wazuh-Regel-ID / Alert-Level) nach dem
  ersten Wazuh-Durchlauf festlegen.
- Elastic-Install-Skripte.

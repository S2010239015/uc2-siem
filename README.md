# UC2 – Vergleich von SIEM-Lösungen (Wazuh vs. Elastic)

Use Case 2 der Masterarbeit *„Aufbau einer CyberRange als Forschungsumgebung zur Untersuchung von Cyber-Resilienz"*. Der Use Case vergleicht zwei SIEM-Lösungen mit unterschiedlichem Erkennungsansatz (log-basiert und prozess-basiert) gegen ein festes Set von elf nachgestellten Angriffen.

Die ganze Umgebung ist als Sandbox-Definition für die Plattform **CyberRangeCZ** beschrieben. Die Definition ist bewusst neutral gehalten. Das SIEM ist nicht Teil der Sandbox, sondern wird erst nach der Allokation im Betrieb installiert. Dadurch bleibt die Umgebung werkzeugunabhängig, und dasselbe Zielsystem lässt sich nacheinander mit beiden SIEMs beobachten.

---

## Inhalt des Repositories

```
uc2-siem/
├── topology.yml                 Topologie der Sandbox (Hosts, Netz, Router, IPs)
├── README.md                    
├── docs/
│   └── ground-truth-events.md   
└── provisioning/
    ├── playbook.yml             Haupt-Playbook, ordnet die Rollen den Hosts zu
    ├── group_vars/all.yml       feste Adressen und schwache Zugangsdaten
    └── roles/
        ├── victim-host/         baut das Zielsystem (Web, DB, Schwächen)
        ├── attacker-host/       baut den Angreifer-Host (Werkzeuge, Szenarien)
        └── siem-host/           legt nur die Install-Skripte ab
```

---

## Topologie

Alle Hosts liegen in einem gemeinsamen Netz (`lab-switch`, 192.168.20.0/24)

| Host     | IP             | Image               | Flavor         | Rolle                          |
|----------|----------------|---------------------|----------------|--------------------------------|
| siem     | 192.168.20.20  | ubuntu-noble-x86_64 | m1.large       | leerer Host mit Install-Skripten |
| victim   | 192.168.20.5   | ubuntu-noble-x86_64 | m1.small       | Zielsystem mit Angriffsfläche  |
| attacker | 192.168.20.30  | ubuntu-noble-x86_64 | m1.small       | Werkzeuge und Szenario-Skripte |
| router   | 192.168.20.1   | debian-12-x86_64    | standard.small | Gateway des Sandbox-Netzes     |

Das Netz ist mit `accessible_by_user: False` definiert. Die Hosts hängen dadurch hinter dem Router und bekommen ihn als Default-Gateway. Der Zugang läuft nicht direkt, sondern über die Management-Kette der Plattform.

---

## Voraussetzungen

- Eine laufende CyberRangeCZ-Instanz. Getestet mit CyberRangeCZ Lite auf Ubuntu 24.04
- Zugang zum Portal mit Rechten, um Trainingsdefinitionen zu importieren und Pools anzulegen.
- Die Sandbox lädt beim Provisionieren Pakete aus dem Internet. Die Install-Skripte für die SIEMs laden im Betrieb weitere Pakete (Wazuh-Repo, Elastic-Repo).

---


### victim-host (Host `victim`)

Das Zielsystem trägt die Angriffsfläche für die Szenarien.

- Apache mit einer PHP-Anwendung und eine MySQL-Datenbank (`firma`).
- Schwacher Benutzer `sysops` mit trivialem Passwort.
- NOPASSWD-sudo und gesetzte SUID-Bits auf `find` und `vim`.
- auditd-Regeln, unter anderem eine Überwachung von Lesezugriffen auf `/etc/shadow` (Schlüssel `shadow_read`).
- Die Datenbank-Zugangsdaten liegen als auffindbare Spur in der Web-Konfiguration, als Ausgangspunkt für Szenario 3.
- Kein SIEM-Agent. Der wird erst im Betrieb installiert.

### attacker-host (Host `attacker`)

Der Angreifer-Host trägt die Werkzeuge und die Szenarien.

- `nmap`, `hydra`, `sshpass` und der MySQL-Client.
- Die drei Szenario-Skripte unter `/opt/scenarios/`.
- Ein Traffic-Generator (`traffic-noise.service`), der laufend die Webseite auf dem Zielsystem abruft. Dieser Normal-Traffic sorgt dafür, dass das SIEM nicht jede Aktivität als anomal wertet.

### siem-host (Host `siem`)

Ein leerer Host. Es werden nur die Install-Skripte unter `/opt/siem/` abgelegt, aber nicht ausgeführt. So lässt sich nach der Allokation entscheiden, welches SIEM installiert wird.

---

## Deployment

Das Deployment läuft komplett über das Portal. Das Repo wird dabei geklont, die Topologie gelesen und das Playbook gegen die neu erstellten Hosts ausgeführt.

1. **Definition importieren.** Portal → *Trainings → Definition → Import*. Repository-URL angeben, Revision leer lassen oder `main` setzen.
2. **Pool anlegen.** Portal → *Sandbox → Pool*. Die importierte Definition zuweisen, Pool-Größe 1.
3. **Sandbox allokieren.** Im Pool eine Sandbox allokieren. Das Provisioning läuft in mehreren Stufen (erst Netzwerk, dann Ansible) und dauert einige Minuten.
4. **Zugangsdaten beziehen.** Nach der Allokation im Pool die Management-SSH-Config und den zugehörigen Key herunterladen 


---

## Zugang

Die Management-Config vom Portal zielt direkt auf den Sandbox-Bastion im internen Netz. Von außen ist dieser nur über den CyberRangeCZ-Host erreichbar. Für den Zugang vom eigenen Rechner wird deshalb ein zusätzlicher Sprung über den Host vorgeschaltet. Die internen IPs ändern sich mit jeder Allokation, die Struktur bleibt gleich.

Beispiel-Config (`~/.ssh/config_uc2`), die Platzhalter an die aktuelle Allokation anpassen:

```
Host cr-host
    HostName <HOST-IP>
    User cyberrangecz

Host bastion
    HostName <BASTION-IP>
    User <default-pXXXX>
    IdentityFile ~/.ssh/pool-id-XX-management-key
    ProxyJump cr-host
    IdentitiesOnly yes
    StrictHostKeyChecking no

Host man
    HostName <MAN-IP>
    User ubuntu
    IdentityFile ~/.ssh/pool-id-XX-management-key
    ProxyJump bastion
    IdentitiesOnly yes
    StrictHostKeyChecking no

Host siem
    HostName <SIEM-IP>
    User ubuntu
    IdentityFile ~/.ssh/pool-id-XX-management-key
    ProxyJump man
    IdentitiesOnly yes
    StrictHostKeyChecking no
    LocalForward 443 127.0.0.1:443
    LocalForward 5601 127.0.0.1:5601

Host victim
    HostName <VICTIM-IP>
    User ubuntu
    IdentityFile ~/.ssh/pool-id-XX-management-key
    ProxyJump man
    IdentitiesOnly yes
    StrictHostKeyChecking no

Host attacker
    HostName <ATTACKER-IP>
    User ubuntu
    IdentityFile ~/.ssh/pool-id-XX-management-key
    ProxyJump man
    IdentitiesOnly yes
    StrictHostKeyChecking no

Host router
    HostName <ROUTER-IP>
    User debian
    IdentityFile ~/.ssh/pool-id-XX-management-key
    ProxyJump man
    IdentitiesOnly yes
    StrictHostKeyChecking no
```

Die beiden `LocalForward`-Zeilen auf `siem` leiten die Weboberflächen der SIEMs durch: Port 443 für das Wazuh-Dashboard und Port 5601 für Kibana. Verbinden:

```
ssh -F ~/.ssh/config_uc2 siem
ssh -F ~/.ssh/config_uc2 attacker
```

---

## SIEM im Betrieb installieren

Nach der Allokation, über die Management-Config. Es läuft immer nur ein SIEM.

### Variante A: Wazuh

Auf `siem` 
```
sudo /opt/siem/install-wazuh-manager.sh
```

Danach auf `victim`:

```
sudo /opt/siem/install-wazuh-agent.sh 192.168.20.20
```

Kontrolle auf `siem`:

```
sudo /var/ossec/bin/agent_control -l
```

Das Wazuh-Dashboard läuft über HTTPS auf Port 443. Zugriff über den SSH-Tunnel, dann im Browser `https://localhost`.

### Variante B: Elastic

Für den Elastic-Lauf die neutrale Umgebung frisch allokieren, damit keine Reste von Wazuh übrig bleiben. Elasticsearch, Kibana und der Fleet-Server laufen auf `siem`, der Elastic Agent mit Elastic Defend auf `victim`. . Kibana läuft auf Port 5601, Zugriff über den zweiten Tunnel unter `http://localhost:5601`.


---

## Szenarien ausführen

Vom `attacker`, in dieser Reihenfolge:

```
/opt/scenarios/scenario1_baseline.sh
/opt/scenarios/scenario2_lotl.sh
/opt/scenarios/scenario3_lateral.sh
```

Die drei Szenarien decken die elf Events mit steigender Tarnung ab:

- **Szenario 1 (Baseline):** Portscan, SSH-Brute-Force, erfolgreicher Login.
- **Szenario 2 (Living off the Land):** sudo-Eskalation, Cron-Persistenz, SUID-Missbrauch, Zugriff auf `/etc/shadow`.
- **Szenario 3 (Lateral / Exfiltration):** Zugangsdaten auslesen, Datenbank-Zugriff, Datenbank-Abzug, Exfiltration.



# UC2 – Vergleich von SIEM-Lösungen (Wazuh vs. Elastic)

Use Case 2 der Masterarbeit *„Aufbau einer CyberRange als Forschungsumgebung zur Untersuchung von Cyber-Resilienz"*. Der Use Case vergleicht zwei SIEM-Lösungen mit unterschiedlichem Erkennungsansatz (log-basiert und prozess-basiert) gegen ein festes Set von elf nachgestellten Angriffen.

Die ganze Umgebung ist als Sandbox-Definition für die Plattform **CyberRangeCZ** beschrieben. Die Definition ist bewusst neutral gehalten. Das SIEM ist nicht Teil der Sandbox, sondern wird erst nach der Allokation im Betrieb installiert. Dadurch bleibt die Umgebung werkzeugunabhängig, und dasselbe Zielsystem lässt sich nacheinander mit beiden SIEMs beobachten.

---

## Inhalt des Repositories

```
uc2-siem/
├── topology.yml                 Topologie der Sandbox (Hosts, Netz, Router, IPs)
├── README.md                    dieses Dokument
├── docs/
│   └── ground-truth-events.md   die elf Ground-Truth-Events und die Metriken
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

Alle Hosts liegen in einem gemeinsamen Netz (`lab-switch`, 192.168.20.0/24), genau wie in UC1.

| Host     | IP             | Image               | Flavor         | Rolle                          |
|----------|----------------|---------------------|----------------|--------------------------------|
| siem     | 192.168.20.20  | ubuntu-noble-x86_64 | m1.large       | leerer Host mit Install-Skripten |
| victim   | 192.168.20.5   | ubuntu-noble-x86_64 | m1.small       | Zielsystem mit Angriffsfläche  |
| attacker | 192.168.20.30  | ubuntu-noble-x86_64 | m1.small       | Werkzeuge und Szenario-Skripte |
| router   | 192.168.20.1   | debian-12-x86_64    | standard.small | Gateway des Sandbox-Netzes     |

Das Netz ist mit `accessible_by_user: False` definiert. Die Hosts hängen dadurch hinter dem Router und bekommen ihn als Default-Gateway. Der Zugang läuft nicht direkt, sondern über die Management-Kette der Plattform.

---

## Voraussetzungen

- Eine laufende CyberRangeCZ-Instanz. Getestet mit CyberRangeCZ Lite auf Ubuntu 24.04, etwa 32 Kerne und 62 GB RAM.
- Zugang zum Portal mit Rechten, um Trainingsdefinitionen zu importieren und Pools anzulegen.
- Die Sandbox lädt beim Provisionieren Pakete aus dem Internet. Die Install-Skripte für die SIEMs laden im Betrieb weitere Pakete (Wazuh-Repo, Elastic-Repo). Die Hosts brauchen dafür ausgehenden Zugang über den Router.

---

## Was die Rollen aufbauen

Das Provisioning baut nur die neutrale Umgebung, kein SIEM.

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
4. **Zugangsdaten beziehen.** Nach der Allokation im Pool die Management-SSH-Config und den zugehörigen Key herunterladen (siehe Abschnitt *Zugang*).

> **Wichtig: Definitionen werden beim Import eingefroren.** Änderungen am Repo greifen nicht durch bloßes Neu-Allokieren. Der richtige Ablauf ist: *push → Definition löschen und neu importieren → neuer Pool → allokieren.* Weicht die Adressvergabe von der Topologie ab, liegt fast immer eine alte, eingefrorene Definition vor. Ein Re-Import behebt das.

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

Nach der Allokation, über die Management-Config. Es läuft immer nur ein SIEM zur Zeit.

### Variante A: Wazuh

Auf `siem` (Manager, Indexer, Dashboard, plus Swap und sysctl):

```
sudo /opt/siem/install-wazuh-manager.sh
```

Danach auf `victim` (Agent, zeigt auf den Manager):

```
sudo /opt/siem/install-wazuh-agent.sh 192.168.20.20
```

Kontrolle auf `siem`:

```
sudo /var/ossec/bin/agent_control -l
```

Das Wazuh-Dashboard läuft über HTTPS auf Port 443. Zugriff über den SSH-Tunnel, dann im Browser `https://localhost`.

### Variante B: Elastic

Für den Elastic-Lauf die neutrale Umgebung frisch allokieren, damit keine Reste von Wazuh übrig bleiben. Elasticsearch, Kibana und der Fleet-Server laufen auf `siem`, der Elastic Agent mit Elastic Defend auf `victim`. Der Aufbau ist mehrstufig und im Kapitel zu Use Case 2 der Masterarbeit beschrieben. Kibana läuft auf Port 5601, Zugriff über den zweiten Tunnel unter `http://localhost:5601`.

Weil jeder Lauf auf einem frischen Host startet, gibt es keine Restzustände zwischen den beiden SIEMs.

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

Die vollständige Definition der Events und die Metriken stehen in [`docs/ground-truth-events.md`](docs/ground-truth-events.md).

---

## Tuning von Wazuh (optional)

Wazuh erkennt den Zugriff auf `/etc/shadow` im Standard nicht, obwohl die auditd-Spur vorhanden ist. Eine lokale Regel schließt diese Lücke. Sie reagiert auf den Audit-Schlüssel `shadow_read` und erzeugt einen Alert auf Stufe 10.

```xml
<group name="audit,local,">
  <rule id="100010" level="10">
    <if_group>audit</if_group>
    <field name="audit.key">shadow_read</field>
    <description>Auditd: Lesezugriff auf /etc/shadow (shadow_read).</description>
    <group>audit_watch_read,pci_dss_10.2.1,</group>
  </rule>
</group>
```

Die Regel wird auf `siem` nach `/var/ossec/etc/rules/local_rules.xml` gelegt, danach den Manager neu starten. Der Schritt ist bewusst nicht Teil des Provisionings, damit der Vorher-Zustand reproduzierbar bleibt.

---

## Bekannte Stolpersteine

Diese Punkte sind Befunde aus dem Betrieb und für die Reproduzierbarkeit wichtig.

- **Swap ist Pflicht.** Der Wazuh-Indexer und Elasticsearch brauchen mehr RAM, als der Host bietet. Das Install-Skript legt deshalb Swap an und setzt `vm.max_map_count`. Ohne diese Schritte bricht der Indexer beim Start ab.
- **Adressabweichung nach Repo-Änderungen.** Weicht die Adressvergabe von der `topology.yml` ab, liegt meist eine eingefrorene, ältere Definition im Portal vor. Ein Re-Import stellt die richtigen Adressen her. Das ist kein Fehler der Provisionierung.
- **Elastic-Regeln laufen im Intervall.** Die Detection Rules von Elastic prüfen nicht in Echtzeit, sondern in einem Intervall (Standard 5 Minuten). Nach einem Angriff erscheinen Alerts erst nach dem nächsten Durchlauf. Wazuh meldet dagegen in Sekunden.
- **Elastic Defend sammelt keine Auth-Logs.** Fehlgeschlagene Logins landen nicht im Standard-Datenstrom von Elastic Defend. Für die Brute-Force-Erkennung muss zusätzlich die System-Integration eingebunden werden, die `/var/log/auth.log` ausliest.

---

## Reproduktion in Kurzform

1. Repo klonen.
2. Definition ins Portal importieren, Pool anlegen, Sandbox allokieren.
3. Management-Config und Key beziehen, `config_uc2` anpassen.
4. Ein SIEM installieren (Wazuh direkt über die Skripte, Elastic mehrstufig).
5. Vom `attacker` die drei Szenarien fahren und die Alerts gegen die Ground-Truth-Liste in `docs/ground-truth-events.md` auswerten.
6. Für den zweiten SIEM-Durchlauf die Umgebung frisch allokieren.

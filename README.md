# UC2 - SIEM-Vergleich (Wazuh vs. Elastic)

Sandbox-Definition für Use Case 2 der Masterarbeit. Drei Hosts in einem
gemeinsamen Netz, zwei SIEMs im Vergleich, drei aufsteigende Szenarien.

## Topologie

Ein einziges Netz `lab-switch` (192.168.20.0/24), analog zu UC1. Das
gemeinsame Netz vermeidet den Default-Route-Konflikt aus der frühen
UC1-Phase.

| Host     | IP             | Flavor       | Rolle        |
|----------|----------------|--------------|--------------|
| siem     | 192.168.20.10  | m1.large     | siem-host    |
| victim   | 192.168.20.20  | m1.small     | victim-host  |
| attacker | 192.168.20.30  | m1.small     | attacker-host|
| router   | 192.168.20.1   | standard.small | -          |

## Kapazitätsentscheidung

`m1.large` (8 GB / 80 GB / 4 vCPU) ist die Obergrenze für den SIEM-Host
unter der aktuellen Auslastung der OpenStack-VM. Die drei Instanzen
belegen zusammen 12 GB RAM und passen in die verfügbaren ~15 GB. Weil
die SIEMs nacheinander laufen, ist nie mehr als ein 8-GB-Host aktiv.

8 GB trifft die offizielle Wazuh-All-in-One-Empfehlung exakt. Für den
Elastic Stack ist es die enge Konfiguration am unteren Rand. Das ist
bewusst so und wird in Kapitel 7 als Einschränkung dokumentiert.

## Umschaltung zwischen den SIEMs

Gesteuert über `siem_stack` in `provisioning/group_vars/all.yml`:

1. `siem_stack: wazuh` - erster Durchlauf (Tag-6-Checkpoint).
2. Nach Abschluss: Wert auf `elastic` ändern, committen, pushen.
3. Sandbox-Definition neu importieren (Revision `main`), neu
   provisionieren.

Die Sandbox friert den Repo-Stand beim Import ein. Änderungen greifen
erst nach erneutem Import, nicht durch bloßes Neu-Allokieren.

## Szenarien

- `scenario1_baseline.sh` - lauter Port-Scan und SSH-Brute-Force,
  funktionsfähig, dient als Kalibrierung.
- `scenario2_lotl.sh` - Living-off-the-Land, Gerüst.
- `scenario3_lateral.sh` - Lateral Movement, Gerüst.

Die konkreten Schritte in Szenario 2 und 3 werden zusammen mit der
Zuordnung der 11 Ground-Truth-Events festgelegt.

## Offen vor dem ersten Durchlauf

- Elastic-Zweig der siem-host-Rolle (nach dem Wazuh-Durchlauf).
- 11 Ground-Truth-Events auf die Szenario-Skripte verteilen.
- Metriken pro Event in die Auswertung übernehmen.

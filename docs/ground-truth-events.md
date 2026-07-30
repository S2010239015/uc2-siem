# UC2 -- Szenarien und Ground-Truth-Events

Kanonische Referenz für den SIEM-Vergleich. Drei Szenarien, aufsteigend
in der Erkennungsschwierigkeit, 11 Ground-Truth-Events. Für jeden Lauf
(Wazuh, danach Elastic) gilt dieselbe Messlatte.

## Umgebung

Drei Hosts in einem gemeinsamen Netz `lab-switch` (192.168.20.0/24).
Ein Netz bewusst, weil getrennte Netze bei UC1 den Default-Route-Konflikt
ausgelöst haben.

| Host     | IP             | Flavor     | Rolle                         |
|----------|----------------|------------|-------------------------------|
| siem     | 192.168.20.20  | m1.large   | SIEM-Server (Wazuh / Elastic) |
| victim   | 192.168.20.5   | m1.small   | Web + DB + normale User       |
| attacker | 192.168.20.30  | m1.small   | Angreifer + Traffic-Rauschen  |
| router   | 192.168.20.1   | standard.small | Gateway                   |

Flavor-Entscheidung: Die ursprüngliche Planung sah `m1.medium` (4 GB)
vor, mit der offenen Frage, ob Elastic darauf läuft. Die Prüfung der
Requirements hat das geklärt: 4 GB liegen unter der Wazuh-Empfehlung
(8 GB) und unter dem Elastic-Minimum. Gewählt wurde `m1.large` (8 GB).
Ein erster Lauf hat bestätigt, dass Wazuh darauf sauber installiert,
ohne OOM und ohne Timeout. Swap bleibt als Sicherheitsnetz gesetzt,
besonders für den Elastic-Lauf.

## SIEMs

Wazuh und Elastic, nacheinander auf derselben Allokation, nie
gleichzeitig. Reihenfolge: Wazuh zuerst (einfacher). Mögliche
Restzustände zwischen den beiden Installationen sind eine bekannte
Einschränkung und gehören in Kapitel 7.

## Szenario 1 -- Baseline / Kontrolle (leicht)

Kette attacker -> victim. Laute, gut signaturisierte Aktivität. Beide
SIEMs sollen alle drei Events treffen. Dient als Beleg, dass der
Messaufbau funktioniert.

| Event | Aktion | Erwartete Erkennung |
|-------|--------|---------------------|
| E1 | `nmap -sV` Port-Scan gegen victim | Portscan erkannt |
| E2 | SSH-Brute-Force (hydra) gegen schwachen User | Brute-Force-Muster, viele Fehllogins |
| E3 | Erfolgreicher Login mit schwachem Passwort | erfolgreicher Login nach Fehlversuchen |

## Szenario 2 -- Insider / Living off the Land (schwer)

Legitimer User auf victim, kein Exploit, keine Malware. Nur Bordmittel.
Hier trennt sich Wazuh (Host-Agent sieht Prozesse und Dateizugriffe)
von Elastic (nur Logs). Diskussionskern der Arbeit.

| Event | Aktion | Erwartete Erkennung |
|-------|--------|---------------------|
| E4 | `sudo` zu ungewöhnlicher Zeit | ungewöhnliche sudo-Nutzung |
| E5 | Neuer Cronjob als Persistenz | Cron-Persistenz |
| E6 | SUID-Ausnutzung (find/vim für Rootshell) | SUID-Missbrauch |
| E7 | Massenlesezugriff auf /etc/shadow und Home-Verzeichnisse | sensibler Dateizugriff |

## Szenario 3 -- Lateral Movement mit Credential-Diebstahl (schwer)

Mehrstufig, Bewegung zwischen Diensten. Der DB-Dienst auf victim ist das
Bewegungsziel. Dass alles auf einem Host liegt, ist eine dokumentierte
Vereinfachung (Kapitel 7).

| Event | Aktion | Erwartete Erkennung |
|-------|--------|---------------------|
| E8 | Credentials auslesen (.bash_history, Config-Dateien) | Credential-Zugriff |
| E9 | Zugriff auf DB-Dienst mit den Credentials | seitliche Bewegung zum DB-Dienst |
| E10 | `mysqldump` des Datenbestands | DB-Dump |
| E11 | Daten rausschleusen (SCP/curl) | Exfiltration |

## Metriken pro Event (für alle gleich)

- Erkannt? ja/nein
- Zeit bis Alert
- Alert-Severity korrekt eingestuft?
- False Positives im selben Zeitfenster

Zusätzlich, als eigene Bewertungsdimension für Szenario 3:

- Korrelation -- erkennt das SIEM die vier Events als eine
  zusammenhängende Kampagne oder als isolierte Einzelereignisse?

## Erkennungskriterium (noch festzulegen)

Damit der Vergleich objektiv ist, wird pro Event vorab definiert, welche
Wazuh-Regel-ID bzw. welches Alert-Level als "erkannt" zählt. Dieselbe
Messlatte gilt dann für den Elastic-Lauf. Diese Zuordnung folgt nach dem
ersten Wazuh-Durchlauf, wenn sichtbar ist, welche Regeln real feuern.

## Rahmenbedingungen aus UC1 (gelten weiter)

- Swap ist Pflicht, sonst OOM-Killer.
- Provisioning ist teils flaky. Mehrfach fehlgeschlagen, dann ohne
  Änderung grün. Netplan-Apply auf dem Router reißt SSH ab, ein Reboot
  heilt das.
- Ohne Traffic-Rauschen markiert das SIEM in Szenario 2 und 3 jede
  Aktivität als anomal. Das Rauschen läuft vom attacker.

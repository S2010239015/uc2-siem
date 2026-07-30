#!/usr/bin/env bash
# Normaler Hintergrund-Traffic. Ruft laufend die Webseite auf victim ab
# und erzeugt darueber auch normale DB-Abfragen. Ohne dieses Rauschen
# wuerde das SIEM in Szenario 2 und 3 jede Aktivitaet als anomal werten.
VICTIM="${VICTIM_IP:-192.168.20.5}"
while true; do
  curl -s "http://${VICTIM}/" >/dev/null 2>&1 || true
  sleep $(( (RANDOM % 20) + 10 ))
done

# Production Setup for Internet Speed Monitoring

Dieses Repository enthält die Konfiguration für den produktiven Betrieb von InfluxDB, Grafana und dem automatischen Speedtest-Monitoring.

## Verzeichnisstruktur
```
production-setup/
├── docker-compose.yml
├── .env_example
├── scripts/
│   ├── install_speedtest_cli.sh
│   └── speedtest-monitor.sh
├── cron/
│   └── speedtest-cron
└── README.md
```

## Vorbereitung
1. `.env_example` kopieren nach `.env` und Werte anpassen.
2. Ordner für Konfiguration anlegen und `.env` verschieben (z.B. `/etc/internet_speed/.env`).
3. Sicherstellen, dass `jq` und `bc` installiert sind:
```bash
   sudo apt update
   sudo apt install jq bc curl
```

## Speedtest CLI Installation

```bash
bash scripts/install_speedtest_cli.sh
```

## Docker Stack starten

```bash
docker-compose up -d
```

## Monitoring-Skript einrichten

```bash
sudo cp scripts/speedtest-monitor.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/speedtest-monitor.sh
```

## Cronjob aktivieren

```bash
sudo crontab -e
# und den Inhalt von cron/speedtest-cron einfügen
```

## Logs & Dashboards

* Logs: `/var/log/speedtest-monitor.log`
* Grafana: `http://<host>:${GRAFANA_HTTP_PORT}`
* Datenquelle: InfluxDB `http://influxdb:8086`, Bucket `internet_speed`

---

# Herangehensweise und Funktionsweise

## Ziel

Ziel war es, eine vollständig automatisierte Lösung zu bauen, die eine VM in Exoscale erstellt und über eine URL technische Details dieser VM ausliefert. Die Lösung soll ohne manuelle Konfiguration auf der VM funktionieren und sowohl eine HTML Website als auch einen JSON API Endpoint bereitstellen.

## Umsetzung

Die Infrastruktur wird deklarativ mit OpenTofu beschrieben. OpenTofu verwendet den Exoscale Provider und erstellt folgende Ressourcen:

1. Eine Security Group für Webzugriff.
2. Ingress-Regeln für HTTP Port 80 und HTTPS Port 443.
3. Optional eine SSH-Regel, wenn explizit ein CIDR gesetzt wird.
4. Eine Ubuntu Compute Instance.
5. Optional einen DNS A-Record in Exoscale DNS.

Die VM verwendet ein offizielles Ubuntu 22.04 LTS Template. Das Template wird über eine Data Source geladen, damit die passende Template-ID in der gewählten Exoscale Zone verwendet wird.

## Automatisierung mit GitHub Actions

Es gibt zwei Workflows:

- `create-infrastructure.yml` führt `tofu init`, `tofu fmt -check`, `tofu validate`, `tofu plan` und `tofu apply` aus.
- `delete-infrastructure.yml` führt `tofu destroy` aus.

Die Exoscale Zugangsdaten werden aus GitHub Secrets gelesen. Dadurch stehen keine Zugangsdaten im Repository.

## Betriebssystemkonfiguration mit Cloud-Init

Die komplette Betriebssystemkonfiguration passiert über `cloud-init.yaml.tftpl`. Cloud-Init führt beim ersten Start der VM folgende Schritte aus:

1. Paketlisten aktualisieren.
2. Nginx, jq, lshw und Certbot installieren.
3. Einen Nginx Virtual Host anlegen.
4. Ein Script unter `/usr/local/bin/render-vm-details.sh` schreiben.
5. Einen systemd Service und Timer einrichten.
6. HTML und JSON direkt beim ersten Start erzeugen.
7. Optional Certbot für HTTPS starten, wenn ein FQDN gesetzt wurde.

Der systemd Timer aktualisiert die Daten alle 60 Sekunden. Dadurch bleiben dynamische Werte wie Uptime, Memory und Filesystem-Nutzung aktuell.

## Website und API

Die Website ist unter `/` erreichbar. Sie zeigt die wichtigsten VM Details in Cards und Tabellen an.

Die JSON API ist unter `/api/v1/vm-details.json` erreichbar. Sie enthält dieselben Informationen in strukturierter Form und eignet sich für automatische Tests.

Beispiele für enthaltene Informationen:

- `network.public_ipv4`
- `operating_system.kernel`
- `compute.hypervisor`
- `compute.memory_total`
- `storage`
- `filesystems`

## DNS und HTTPS

DNS und HTTPS sind optional umgesetzt.

Wenn `dns_domain` leer bleibt, wird keine DNS-Ressource erstellt und die VM ist über ihre öffentliche IP per HTTP erreichbar.

Wenn `dns_domain` gesetzt wird, sucht OpenTofu die vorhandene Exoscale DNS Zone und erstellt einen A-Record auf die öffentliche IP der VM. Danach versucht Cloud-Init mit Certbot ein Let's Encrypt Zertifikat zu erstellen und Nginx auf HTTPS mit Redirect umzustellen.

Dieser Ansatz wurde gewählt, weil Let's Encrypt ein öffentlich auflösbares FQDN benötigt und keine Zertifikate für reine IP-Adressen ausstellt.

## Verwendung bei der Beurteilung

Für die Beurteilung kann der Create Workflow manuell gestartet werden. Nach Abschluss stehen die relevanten URLs in den Workflow Outputs:

- `http_url`
- `https_url`
- `json_api_url`

Die Prüfer können zuerst die Website öffnen und anschließend die JSON API testen. Nach der Prüfung kann der Delete Workflow gestartet werden, um alle Ressourcen wieder zu entfernen.

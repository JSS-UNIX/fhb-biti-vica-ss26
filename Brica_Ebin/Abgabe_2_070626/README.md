# Virtualisierung - Abgabe 2

## Autor

**Ebin Brica**

## Ziel der Aufgabe

Ziel dieser Aufgabe ist die vollständig automatisierte Erstellung einer Cloud Infrastruktur in Exoscale.

Nach erfolgreicher Ausführung wird eine Ubuntu VM erstellt, welche über einen HTTP Endpunkt erreichbar ist.

Die Webseite stellt technische Informationen über die virtuelle Maschine bereit.

Angezeigte Informationen:

- Öffentliche IP-Adresse
- Kernel Version
- Arbeitsspeicher
- Speichergröße
- Dateisystem
- Hypervisor Informationen


---

# Verwendete Technologien

- Exoscale Cloud Plattform
- OpenTofu / Terraform
- GitHub Actions
- Ubuntu Linux
- CloudInit
- Apache Webserver
- HTML
- JSON


---

# Aufbau der Lösung


## Terraform / OpenTofu

Die Infrastruktur wird vollständig automatisch mit OpenTofu erstellt.

Folgende Ressourcen werden erstellt:

- Ubuntu 24.04 VM
- Security Group
- Firewall Regeln für HTTP und SSH

Die wichtigsten Dateien:

| Datei | Beschreibung |
|---|---|
| main.tf | Erstellt die Exoscale Infrastruktur |
| variables.tf | Definiert benötigte Variablen |
| outputs.tf | Gibt IP und URLs aus |
| cloud-init.yaml | Automatische Betriebssystemkonfiguration |


---

# CloudInit

Die komplette Konfiguration des Betriebssystems erfolgt automatisch über CloudInit.

CloudInit führt folgende Schritte aus:

1. Aktualisieren der Pakete
2. Installation von Apache
3. Sammeln der VM Informationen
4. Erzeugen einer HTML Webseite
5. Erzeugen eines JSON API Endpunktes


---

# GitHub Workflows


## Infrastruktur erstellen

Workflow:

```
.github/workflows/create-infra.yml
```

Funktion:

- OpenTofu installieren
- Terraform Initialisierung durchführen
- Exoscale VM erstellen
- IP Adresse ausgeben


## Infrastruktur löschen

Workflow:

```
.github/workflows/destroy-infra.yml
```

Funktion:

- bestehende Infrastruktur entfernen
- Exoscale Ressourcen löschen


---

# Verwendung


## 1. GitHub Secrets erstellen

Folgende Secrets müssen vorhanden sein:

```
EXOSCALE_API_KEY
EXOSCALE_API_SECRET
```


## 2. Infrastruktur erstellen

GitHub:

Actions

→ Create Infrastructure

→ Run Workflow


Nach erfolgreicher Erstellung wird die IP Adresse ausgegeben.


---

# Endpunkte


## HTML Webseite

```
http://<PUBLIC-IP>/
```


## JSON API

```
http://<PUBLIC-IP>/api
```


---

# Löschen der Umgebung

Zum Entfernen der VM:

Actions

→ Destroy Infrastructure

→ Run Workflow


Dadurch werden alle erzeugten Exoscale Ressourcen wieder entfernt.

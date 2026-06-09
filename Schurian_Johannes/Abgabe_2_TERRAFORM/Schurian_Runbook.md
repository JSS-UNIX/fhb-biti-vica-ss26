# Runbook – Automatisierte VM-Infrastruktur auf Exoscale

> **Projekt:** BITI VICA SS26 – Abgabe 2  
> **Autor:** Johannes Schurian  
> **Ziel:** Automatisierte Erstellung einer Ubuntu VM auf Exoscale, die per HTTP technische Details über sich selbst ausliefert.

---

## Inhaltsverzeichnis

1. [Architekturüberblick](#1-architekturüberblick)
2. [Voraussetzungen](#2-voraussetzungen)
3. [Herangehensweise](#3-herangehensweise)
4. [Datei: `main.tf` – Infrastrukturdefinition](#4-datei-maintf--infrastrukturdefinition)
5. [Datei: `cloud-init.yml` – OS-Konfiguration](#5-datei-cloud-inityml--os-konfiguration)
6. [Dateien: `schurian_deploy.yml` – Infrastruktur erstellen & `schurian_destroy.yml` – Infrastruktur löschen](#6-dateien-schurian_deployyml--infrastruktur-erstellen--schurian_destroyyml--infrastruktur-löschen)
7. [Probleme mit Terraform-State-File](#7-probleme-mit-terraform-state-file)

---

## 1. Architekturüberblick

```
┌──────────────────────────────────────────────┐
│              GitHub Repository               │
│                                              │
│  schurian_deploy.yml  ──►  Terraform Apply   │
│  schurian_destroy.yml ──►  Terraform Destroy │
│                                              │
│  terraform.tfstate  (im Repo gespeichert)    │
└──────────────────┬───────────────────────────┘
                   │ Exoscale API
                   ▼
┌──────────────────────────────────────────────┐
│              Exoscale (at-vie-1)             │
│                                              │
│  Security Group: HTTP (80) + HTTPS (443)     │
│                                              │
│  VM: Ubuntu 24.04 LTS (standard.micro)       │
│    └─► Cloud-Init konfiguriert beim Boot:    │
│          - nginx installieren & starten      │
│          - index.html mit VM-Details         │
│            generieren                        │
└──────────────────────────────────────────────┘
                   │
            Öffentliche IP
                   │
         http://85.217.173.48/  →  VM-Dashboard
```

---

## 2. Voraussetzungen

### GitHub Secrets

Im Repository unter **Settings → Secrets and variables → Actions** müssen zwei Secrets angelegt sein:

| Secret Name | Inhalt |
|---|---|
| `EXOSCALE_API_KEY` | Exoscale API Key hinterlegt |
| `EXOSCALE_API_SECRET` | API Secret hinterlegt |

### Repository-Struktur

Die Dateien müssen im Repository unter folgendem Pfad liegen, da die Workflows mit `working-directory` darauf zeigen:

```
repository-root/
└── Schurian_Johannes/
    └── Abgabe_2_TERRAFORM/
        ├── main.tf
        ├── cloud-init.yml
        ├── terraform-tfstate
        ├── NGINX.png
        └── Schurian_Runbook
```

Die Workflow-Dateien liegen wie üblich unter:
```
.github/
└── workflows/
    ├── schurian_deploy.yml
    └── schurian_destroy.yml
```
---

## 3. Herangehensweise

Die Aufgabe wurde in drei Ausführungsebenen unterteilt:

## 4. Datei: `main.tf` – Infrastrukturdefinition

**(Terraform-Config):** Die `main.tf` erstellt ein VM mit integriertes SecurityGroup auf Exoscale mit der letzten Ubuntu:latest Image. Der generierte Webserver kommuniziert direkt Ports 80/443.

#### Erstellte Ressourcen im Überblick

| Ressource | Name | Details |
|---|---|---|
| Security Group | `jschurian-security-policies` | Erlaubt Port 80 + 443 von überall |
| Compute Instance | `Johannes-Schurian NGINX-Web-Server` | Ubuntu, `standard.micro`, 10 GB |

---

## 5. Datei: `cloud-init.yml` – OS-Konfiguration

**(Cloud-Init-Config):** Die `cloud-init.yml` führt eine Aktualisierung des Systems aus und führt zudem das darin enthaltene Script aus. Das Skript liefert als Ergebnis ein statischen Snapshot des Servers zurück.

#### Was wird angezeigt?

Das fertige Dashboard sah folgendermaßen aus:

![Exoscale-Dashboard](/images/NGINX.png)

---

## 6. Dateien: `schurian_deploy.yml` – Infrastruktur erstellen & `schurian_destroy.yml` – Infrastruktur löschen

**(GitHub Actions):** Um die Service in Exoscale auszurollen gibts es zwei separate GitHub Actions Workflows (`Deploy Infrastructure - Schurian ` und `Destroy Infrastructure - Schurian`), welche manuell gestartetwerden müssen.


#### Ablauf des Workflows

```
Run workflow		   → Manueller Trigger
       │
       ▼
Checkout Code          → Repository-Inhalt auf Runner laden
       │
       ▼
Setup Terraform        → Terraform CLI installieren
       │
       ▼
Terraform Init         → Exoscale Provider herunterladen
       │
       ▼
Terraform Plan         → Geplante Änderungen anzeigen (kein Apply)
       │
       ▼
Terraform Apply        → Ressourcen auf Exoscale erstellen
       │                  (Security Group + VM)
       ▼
Commit Terraform State → terraform.tfstate ins Repo pushen
                         (für späteres Destroy benötigt)
```

---

## 7. Probleme mit Terraform-State-File

Die Entwicklung des `Deploy-Infrastrcuture` verlief mehr oder minder ohne größere Probleme jedoch musste ich beim bei dem Teil mit `Destroy-Infrastrcuture` feststellen das dieser Teil immer erfolgreich jedoch ohne Löschung des entsprechnden Images ausführen lies. Mit Recherche und KI-Hilfe fand ich heraus das Terraform den aktuele VM Status (eben das tfstate File) nicht übernahm und daher bei der versuxchten Löschung des Images davon ausging das es eh nichts zu löschen gebe. Als alternativen Workaround fand ich eine Möglichkeit mittels Git Bot das aktualisierte `terraform.tfstate` File mittles Git-Commit zurück in die entsprechnde Repo pushen. Danach lies sich der `Destroy-Infrastrcuture` Workflow ohne weitere Fehler ausführen.

---


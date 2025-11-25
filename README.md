# 🏭 Industrie 4.0 Monitoring Stack (ExtrusionOS/Spectre)

[![Lizenz: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![NixOS](https://img.shields.io/badge/NixOS-24.05-blue.svg)](https://nixos.org/)
[![DevSecOps](https://img.shields.io/badge/DevSecOps-Ready-green.svg)](https://www.devsecops.org/)

> **Produktionsreife Monitoring-Lösung für global verteilte Industrie 4.0-Systeme, die ExtrusionOS- und Spectre-Anwendungen auf NixOS-Infrastruktur ausführen.**

![Industrial Monitoring Dashboard](docs/assets/hero.png)

## 📑 Management Summary (Lösungskonzept)

Diese Lösung bietet ein zentralisiertes, sicheres und skalierbares Monitoring-Konzept für die weltweit verteilten Reifenhäuser-Systeme. Durch den Einsatz von **NixOS** wird eine reproduzierbare und gehärtete Infrastruktur gewährleistet ("Infrastructure as Code"). Der **ELK-Stack** (Elasticsearch, Logstash, Kibana) ermöglicht eine tiefgehende Analyse von Anwendungslogs, während **Prometheus & Grafana** Echtzeit-Metriken und Alarmierung bereitstellen.

**Highlights:**
*   **Sicherheit**: Durchgängige Verschlüsselung (mTLS, VPN, Secrets) und Zero-Trust-Ansatz.
*   **Automatisierung**: Vollständige Automatisierung von Deployment und Konfiguration.
*   **Skalierbarkeit**: Modulare Architektur, bereit für wachsendes Datenvolumen.


## 📋 Inhaltsverzeichnis

- [Überblick](#überblick)
- [Deployment-Optionen](#deployment-optionen)
- [Architektur](#architektur)
- [Technologie-Stack & Begründung](#technologie-stack--begründung)
- [Sicherheitsfunktionen](#sicherheitsfunktionen)
- [Schnellstart](#schnellstart)
- [Konfiguration](#konfiguration)
- [Monitoring-Funktionen](#monitoring-funktionen)
- [Einschränkungen & Zukünftige Verbesserungen](#einschränkungen--zukünftige-verbesserungen)

---

## 🎯 Überblick

Dieser Monitoring-Stack adressiert die Herausforderung, verteilte industrielle Systeme zu verwalten, die an Kundenstandorten weltweit eingesetzt werden. Er bietet:

- ✅ Echtzeit-Überwachung des Zustands von Hosts und internen Anwendungen
- ✅ Anomalieerkennung und Alarmierung
- ✅ Analyse historischer Daten und Statistiken
- ✅ Sicheres Secret-Management
- ✅ Zero-Trust-Sicherheitsmodell
- ✅ Minimaler operativer Aufwand

### Problemstellung

Die manuelle Überwachung von ExtrusionOS/Spectre-Systemen über mehrere Kundenstandorte hinweg wird mit zunehmender Skalierung der Infrastruktur untragbar. Diese Lösung bietet zentrale Sichtbarkeit bei gleichzeitiger Einhaltung der Sicherheits- und Compliance-Anforderungen für industrielle Umgebungen.

---

## 🚀 Deployment-Optionen

Dieses Projekt unterstützt **zwei Deployment-Strategien** für maximale Flexibilität:

### 🐳 Docker Compose (Empfohlen für Entwicklung/Einzelserver)

**Vorteile:**
- ✅ Einfaches Setup (< 5 Minuten)
- ✅ Minimaler Ressourcenverbrauch
- ✅ Ideal für Entwicklung und Testing
- ✅ Perfekt für Einzelserver-Deployments

**Schnellstart:**
```bash
docker compose up -d
```

**Wann nutzen:**
- Lokale Entwicklung
- CI/CD Testing
- Einzelserver-Produktionsumgebungen
- Proof of Concepts

---

### ☸️ Kubernetes/K3s (Empfohlen für Produktion/Multi-Site)

**Vorteile:**
- ✅ High Availability (Multi-Replica)
- ✅ Auto-Scaling
- ✅ Rolling Updates (Zero Downtime)
- ✅ Self-Healing
- ✅ Multi-Node Support
- ✅ Production-Grade Features

**Schnellstart:**
```bash
# Mit Kustomize
kubectl apply -k k8s/

# Oder auf NixOS mit K3s
nixos-rebuild switch --flake .#server
```

**Wann nutzen:**
- Produktionsumgebungen
- Multi-Site Deployments
- High-Availability Anforderungen
- Cloud-Native Infrastruktur
- Edge/Industrial Deployments (K3s)

---

### 📊 Vergleich

| Feature | Docker Compose | Kubernetes/K3s |
|---------|----------------|----------------|
| **Setup-Zeit** | 5 Minuten | 30 Minuten |
| **Komplexität** | Niedrig | Mittel |
| **High Availability** | ❌ Nein | ✅ Ja |
| **Auto-Scaling** | ❌ Nein | ✅ Ja |
| **Rolling Updates** | ❌ Nein | ✅ Ja |
| **Multi-Node** | ❌ Nein | ✅ Ja |
| **Ressourcen (Min)** | 2 CPU, 4GB RAM | 2 CPU, 5GB RAM |
| **Best For** | Dev/Test/Single | Production/Multi-Site |

> [!NOTE]
> **Beide Deployment-Methoden nutzen dieselben Container-Images und Konfigurationsdateien.**
> Sie können mit Docker Compose beginnen und später zu Kubernetes migrieren, ohne Ihre Konfiguration neu schreiben zu müssen.

**Detaillierte Informationen:**
- [Kubernetes Deployment Guide](k8s/README.md)
- [Deployment Strategy Documentation](docs/deployment-strategy.md)

---

## 🏗️ Architektur

```
┌─────────────────────────────────────────────────────────────┐
│                    Monitoring Server (Zentral)              │
│  ┌────────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │Elasticsearch│ │ Kibana   │  │Prometheus│  │ Grafana  │   │
│  │   (Logs)   │  │(Dashboards)││ (Metriken)│ │(Analytics)│  │
│  └────────────┘  └──────────┘  └──────────┘  └──────────┘   │
│         │              │               │             │      │
│  ┌────────────────────────────────────────────────────────┐ │
│  │             Nginx (Reverse Proxy + mTLS)               │ │
│  └────────────────────────────────────────────────────────┘ │
└───────────────────────────┬─────────────────────────────────┘
                            │ mTLS + VPN
                ┌───────────┴───────────┐
                │                       │
        ┌───────▼────────-┐      ┌──────▼────────┐
        │Kundenstandort 1 │      │ Kundenstandort N │
        │                 │      │               │
        │ ┌─────────────┐ │      │┌─────────────┐│
        │ │  Filebeat   │ │      ││  Filebeat   ││
        │ │  (Logs)     │ │      ││  (Logs)     ││
        │ └─────────────┘ │      │└─────────────┘│
        │ ┌─────────────┐ │      │┌─────────────┐│
        │ │Node Exporter│ │      ││Node Exporter││
        │ │  (Metriken) │ │      ││  (Metriken) ││
        │ └─────────────┘ │      │└─────────────┘│
        │ ┌─────────────┐ │      │┌─────────────┐│
        │ │ExtrusionOS/ │ │      ││ExtrusionOS/ ││
        │ │  Spectre    │ │      ││  Spectre    ││
        │ └─────────────┘ │      │└─────────────┘│
        └─────────────────┘      └───────────────┘
```

---

## 🛠️ Technologie-Stack & Begründung

### Kernkomponenten

| Komponente | Zweck | Begründung |
|-----------|---------|-----------|
| **Elasticsearch** | Log-Aggregation & Suche | Industriestandard für Log-Management, leistungsstarke Abfragen, horizontale Skalierung |
| **Kibana** | Log-Visualisierung | Native Integration mit Elasticsearch, umfangreiche Dashboards, Anomalieerkennung |
| **Prometheus** | Metrik-Erfassung | Pull-basiertes Modell ideal für dynamische Umgebungen, PromQL für komplexe Abfragen |
| **Grafana** | Metrik-Visualisierung | Überlegene Visualisierung, Alarmierung, unterstützt mehrere Datenquellen |
| **Filebeat** | Log-Versand | Leichtgewichtig, zuverlässig, Backpressure-Handling |
| **Node Exporter** | System-Metriken | Standard Prometheus-Exporter, umfassende Hardware/OS-Metriken |
| **Nginx** | Reverse Proxy | mTLS-Terminierung, Load Balancing, sichere Client-Authentifizierung |
| **WireGuard** | VPN-Konnektivität | Modernes, schnelles, sicheres Tunneling für verteilte Standorte |
| **SOPS + age** | Secret-Management | Deklarative Verschlüsselung für NixOS, GitOps-freundlich |

### Warum dieser Stack?

1. **ELK Stack**: Best-in-Class für Log-Analyse in industriellen Umgebungen
2. **Prometheus/Grafana**: Zeitreihen-Metriken mit leistungsstarker Alarmierung
3. **NixOS Integration**: Deklarative Konfiguration, reproduzierbare Builds
4. **Security First**: mTLS, VPN, verschlüsselte Secrets, Least Privilege
5. **Operative Einfachheit**: Automatisierte Deployments, Self-Healing

---

## 🔒 Sicherheitsfunktionen

### Defense in Depth

1. **Netzwerkschicht**
   - WireGuard VPN für die gesamte Client-Server-Kommunikation
   - mTLS-Zertifikatsauthentifizierung (keine Passwörter)
   - IP-Whitelisting pro Kundenstandort

2. **Anwendungsschicht**
   - Nginx Rate Limiting und DDoS-Schutz
   - Read-only Filebeat-Konfigurationen auf Clients
   - Separate Service-Accounts pro Komponente

3. **Secret-Management**
   - SOPS-Verschlüsselung für alle Secrets
   - Unterstützung für Age-Key-Rotation
   - Keine Klartext-Zugangsdaten in Git

4. **Systemhärtung**
   - AppArmor-Profile für alle Dienste
   - Minimale Container-Images (Distroless wo möglich)
   - Automatisierte Sicherheitsupdates via NixOS

5. **Audit & Compliance**
   - Alle Zugriffe werden in Elasticsearch protokolliert
   - Unveränderlicher Audit-Trail
   - DSGVO-konforme Datenaufbewahrungsrichtlinien

---

## 🚀 Schnellstart

### Voraussetzungen

- NixOS 24.05+ (Server und Clients)
- Docker & Docker Compose (für Entwicklung)
- `sops` und `age` für Secret-Management
- 4GB RAM Minimum (Server), 512MB (Clients)

### 1. Repository klonen

```bash
git clone https://github.com/AlexanderMonsanto/reifenhaeuser-nixos-elk.git
cd reifenhaeuser-nixos-elk
```

### 2. Setup & Secrets generieren

Führen Sie den automatisierten Setup-Befehl aus. Dieser generiert:
- `.env` Datei mit sicheren Passwörtern
- Age-Key für SOPS
- mTLS Zertifikate
- WireGuard Schlüssel

```bash
make setup
```

Anschließend verschlüsseln Sie die Secrets:

```bash
# Secrets verschlüsseln
sops -e -i secrets/secrets.yaml
```

### 3. Monitoring-Server bereitstellen

```bash
# Mit Docker Compose (Entwicklung)
docker-compose up -d

# Mit NixOS (Produktion)
sudo nixos-rebuild switch --flake .#monitoring-server
```

### 4. Client-Agenten bereitstellen

```bash
# Auf Client-Systemen
sudo nixos-rebuild switch --flake .#monitoring-client
```

### 5. Zugriff auf Dashboards

- **Kibana**: https://monitoring.example.com:5601
- **Grafana**: https://monitoring.example.com:3000

Standard-Zugangsdaten befinden sich in `secrets/secrets.yaml` (verschlüsselt).

---

## ⚙️ Konfiguration

### Server-Konfiguration

Der Monitoring-Server wird über `nixos/server/configuration.nix` konfiguriert:

```nix
# Wichtige Konfigurationsoptionen
services.elasticsearch.enable = true;
services.kibana.enable = true;
services.prometheus.enable = true;
services.grafana.enable = true;

# Sicherheitshärtung
security.apparmor.enable = true;
networking.firewall.allowedTCPPorts = [ 443 ];  # Nur HTTPS
```

### Client-Konfiguration

Clients verwenden `nixos/client/configuration.nix`:

```nix
# Filebeat für Log-Versand
services.filebeat = {
  enable = true;
  settings = {
    filebeat.inputs = [
      {
        type = "log";
        paths = [ "/var/log/extrusionos/*.log" ];
      }
    ];
  };
};

# Prometheus Node Exporter
services.prometheus.exporters.node.enable = true;
```

### Secret-Management

Secrets werden mit SOPS verschlüsselt:

```yaml
# secrets/secrets.yaml
elasticsearch_password: ENC[AES256_GCM,data:xyz...]
kibana_encryption_key: ENC[AES256_GCM,data:abc...]
```

---

## 📊 Monitoring-Funktionen

### System-Metriken (Prometheus)

- CPU-Auslastung pro Kern
- Speichernutzung und Swap
- Festplatten-I/O und Speicherplatz
- Netzwerkdurchsatz
- System Load Averages

### Anwendungs-Logs (ELK)

- ExtrusionOS Prozess-Logs
- Spectre Anwendungsfehler
- System-Journal (systemd)
- Audit-Logs

### Alarmierungsregeln

Vorkonfigurierte Alarme für:

- Hohe CPU-Auslastung (>80% für 5 Min)
- Geringer Festplattenspeicher (<10%)
- Dienstausfälle
- Anomale Log-Muster
- Netzwerkverbindungsprobleme

### Dashboards

- **Systemübersicht**: Alle Hosts auf einen Blick
- **Anwendungsstatus**: ExtrusionOS/Spectre Status
- **Netzwerk**: Bandbreite und Latenz
- **Sicherheit**: Fehlgeschlagene Anmeldeversuche, Anomalien

---

## 🔍 Einschränkungen & Zukünftige Verbesserungen

### Aktuelle Einschränkungen

1. **Skalierbarkeit**: Einzelner Monitoring-Server (SPOF)
2. **Bandbreite**: Vollständiger Log-Versand kann Standorte mit geringer Bandbreite belasten
3. **Speicher**: Keine automatisierte Log-Rotation/Archivierung
4. **Alarmierung**: Basisregeln, keine ML-basierte Anomalieerkennung
5. **Mandantenfähigkeit**: Nicht optimiert für die Isolierung von Kundendaten

### Roadmap

#### Phase 1 (Q1 2026)
- [ ] Hochverfügbares Elasticsearch-Cluster (3 Knoten)
- [ ] Log-Sampling für bandbreitenbeschränkte Standorte
- [ ] Automatisiertes Index Lifecycle Management (ILM)
- [ ] Machine Learning Anomalieerkennung (Elastic ML)

#### Phase 2 (Q2 2026)
- [ ] Mandantenfähigkeit mit rollenbasierter Zugriffskontrolle (RBAC)
- [ ] S3-kompatibler Cold Storage für historische Logs
- [ ] Benutzerdefinierte ExtrusionOS/Spectre Dashboards
- [ ] Synthetisches Monitoring (Uptime Checks)

#### Phase 3 (Q3 2026)
- [ ] OpenTelemetry-Integration für Distributed Tracing
- [ ] Predictive Maintenance Modelle
- [ ] Mobile App für On-Call-Alarme
- [ ] Integration mit Ticketing-Systemen (Jira, ServiceNow)

---

## 📚 Dokumentation

- [Installationsanleitung](docs/installation.md)
- [Sicherheitshärtung](docs/security.md)
- [Fehlerbehebung](docs/troubleshooting.md)
- [API-Referenz](docs/api.md)

---

## 🤝 Mitwirken

Beiträge sind willkommen! Bitte lesen Sie [CONTRIBUTING.md](CONTRIBUTING.md) für Richtlinien.

---

## 📄 Lizenz

MIT Lizenz - siehe [LICENSE](LICENSE) für Details.

---

## 👥 Autoren

- Alexander Monsanto - Riefenhäuser ELK Project - [MyGitHub](https://github.com/AlexanderMonsanto)

---

## 🙏 Danksagung

- Reifenhäuser Gruppe für den industriellen Anwendungsfall
- NixOS Community für deklarative Infrastruktur
- Elastic und Grafana Labs für exzellente Monitoring-Tools

---

**Entwickelt mit ❤️ für Industrie 4.0**

---

## ✅ Erfüllung der Anforderungen (Solution Mapping)

| Anforderung (aus Aufgabenstellung) | Umsetzung im Projekt |
|-----------------------------------|----------------------|
| **Konzept entwickeln** | Siehe [Architektur](#architektur) und [Technologie-Stack](#technologie-stack--begründung). Das Konzept basiert auf einer Hub-and-Spoke Architektur mit zentralem Server und dezentralen Clients. |
| **Technologieauswahl erklären** | Siehe [Technologie-Stack & Begründung](#technologie-stack--begründung). Detaillierte Tabelle mit Begründung für jede Komponente (ELK, Prometheus, WireGuard, etc.). |
| **NixOS Konfiguration (Server)** | Siehe `nixos/server/configuration.nix`. Beinhaltet Docker, Firewall, WireGuard und Systemhärtung. |
| **Secret Management & Absicherung** | Siehe [Sicherheitsfunktionen](#sicherheitsfunktionen). Implementiert mit **SOPS** (`secrets/secrets.yaml`), **mTLS** (`config/nginx/conf.d/monitoring.conf`) und **AppArmor**. |
| **Umsetzung Clientseite** | Siehe `nixos/client/configuration.nix`. Konfiguration von **Filebeat** und **Node Exporter** sowie WireGuard-VPN. |
| **Ausblick & Verbesserungen** | Siehe [Einschränkungen & Zukünftige Verbesserungen](#einschränkungen--zukünftige-verbesserungen). Roadmap für Skalierung und Features. |
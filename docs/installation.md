# Installationsanleitung

## Voraussetzungen

Bevor Sie beginnen, stellen Sie sicher, dass die folgenden Tools installiert sind.

### 1. Docker & Docker Compose
Erforderlich für das Ausführen des Stacks im Entwicklungsmodus.

- **Ubuntu/Debian**:
  ```bash
  sudo apt update
  sudo apt install docker.io docker-compose
  sudo usermod -aG docker $USER
  newgrp docker
  ```
- **NixOS**:
  Fügen Sie dies zu Ihrer `configuration.nix` hinzu:
  ```nix
  virtualisation.docker.enable = true;
  users.users.<ihr-benutzer>.extraGroups = [ "docker" ];
  ```
- **macOS**: Installieren Sie [Docker Desktop](https://www.docker.com/products/docker-desktop/).

### 2. WireGuard
Erforderlich für die sichere Kommunikation zwischen den Knoten.

- **Ubuntu/Debian**:
  ```bash
  sudo apt install wireguard
  ```
- **NixOS**:
  Fügen Sie dies zu Ihrer `configuration.nix` hinzu:
  ```nix
  networking.wireguard.enable = true;
  ```
- **macOS**: Installieren Sie es über den App Store oder `brew install wireguard-tools`.

### 3. SOPS & Age
Erforderlich für das Secret-Management.

- **Linux (Binary)**:
  ```bash
  # Age installieren
  curl -LO https://github.com/FiloSottile/age/releases/latest/download/age-v1.0.0-linux-amd64.tar.gz
  tar xf age-v1.0.0-linux-amd64.tar.gz
  sudo mv age/age /usr/local/bin/
  sudo mv age/age-keygen /usr/local/bin/

  # SOPS installieren
  curl -LO https://github.com/getsops/sops/releases/latest/download/sops-v3.7.3.linux.amd64
  sudo mv sops-v3.7.3.linux.amd64 /usr/local/bin/sops
  sudo chmod +x /usr/local/bin/sops
  ```
- **NixOS**:
  ```nix
  environment.systemPackages = with pkgs; [ sops age ];
  ```
- **macOS**:
  ```bash
  brew install sops age
  ```

## Schritte

1. Repository klonen.
2. Führen Sie `./scripts/setup.sh` aus, um Secrets und Zertifikate zu initialisieren.
3. Verschlüsseln Sie die Secrets mit SOPS.
4. Führen Sie `docker-compose up -d` aus, um den Server-Stack zu starten.
5. Deployen Sie die NixOS-Clients unter Verwendung des Flakes.

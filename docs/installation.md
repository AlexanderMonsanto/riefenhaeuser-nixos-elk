# Installation Guide

## Prerequisites

Before you begin, ensure you have the following tools installed.

### 1. Docker & Docker Compose
Required for running the stack in development mode.

- **Ubuntu/Debian**:
  ```bash
  sudo apt update
  sudo apt install docker.io docker-compose
  sudo usermod -aG docker $USER
  newgrp docker
  ```
- **NixOS**:
  Add to your `configuration.nix`:
  ```nix
  virtualisation.docker.enable = true;
  users.users.<your-user>.extraGroups = [ "docker" ];
  ```
- **macOS**: Install [Docker Desktop](https://www.docker.com/products/docker-desktop/).

### 2. WireGuard
Required for secure communication between nodes.

- **Ubuntu/Debian**:
  ```bash
  sudo apt install wireguard
  ```
- **NixOS**:
  Add to `configuration.nix`:
  ```nix
  networking.wireguard.enable = true;
  ```
- **macOS**: Install via App Store or `brew install wireguard-tools`.

### 3. SOPS & Age
Required for secret management.

- **Linux (Binary)**:
  ```bash
  # Install Age
  curl -LO https://github.com/FiloSottile/age/releases/latest/download/age-v1.0.0-linux-amd64.tar.gz
  tar xf age-v1.0.0-linux-amd64.tar.gz
  sudo mv age/age /usr/local/bin/
  sudo mv age/age-keygen /usr/local/bin/

  # Install SOPS
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

## Steps
1. Clone the repository.
2. Run `./scripts/setup.sh` to initialize secrets and certificates.
3. Encrypt secrets using SOPS.
4. Run `docker-compose up -d` to start the server stack.
5. Deploy NixOS clients using the flake.

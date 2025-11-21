{ config, pkgs, ... }:

{
  imports = [ ./secrets.nix ];

  networking.hostName = "monitoring-server";
  networking.firewall.allowedTCPPorts = [ 80 443 9200 5601 3000 9090 9093 6443 ]; # 6443 = K3s API
  networking.firewall.allowedUDPPorts = [ 51820 ]; # WireGuard

  # Enable Docker (for Docker Compose deployment)
  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune.enable = true;

  # K3s Kubernetes (optional, for Kubernetes deployment)
  # Uncomment to use Kubernetes instead of Docker Compose
  # services.k3s = {
  #   enable = true;
  #   role = "server";
  #   extraFlags = toString [
  #     "--disable=traefik"  # Use Nginx instead
  #     "--write-kubeconfig-mode=644"
  #   ];
  # };

  # System packages
  environment.systemPackages = with pkgs; [
    docker-compose
    git
    vim
    htop
    sops
    # Kubernetes tools (uncomment if using K3s)
    # kubectl
    # kubernetes-helm
    # k9s
  ];

  # WireGuard Server
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.100.0.1/24" ];
      listenPort = 51820;
      privateKeyFile = config.sops.secrets."wireguard/server_private_key".path;
      peers = [
        { # Client 1
          publicKey = "CLIENT_PUBLIC_KEY_PLACEHOLDER";
          allowedIPs = [ "10.100.0.2/32" ];
        }
      ];
    };
  };

  system.stateVersion = "24.05";
}

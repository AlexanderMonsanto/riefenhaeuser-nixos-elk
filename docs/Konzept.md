docs/KONZEPT.md
```
# Industrial Monitoring Stack - Complete Project Structure

## 📁 Directory Structure

```
industrial-monitoring-stack/
├── README.md                          # Main documentation
├── LICENSE                            # MIT License
├── .gitignore                         # Git ignore rules
├── .env.example                       # Environment variables template
├── .sops.yaml                         # SOPS configuration
├── docker-compose.yml                 # Docker Compose orchestration
├── Makefile                           # Common tasks automation
│
├── docs/                              # Additional documentation
│   ├── installation.md
│   ├── security.md
│   ├── troubleshooting.md
│   ├── architecture.md
│   └── api.md
│
├── scripts/                           # Automation scripts
│   ├── setup.sh                       # Initial setup script
│   ├── generate-certs.sh              # Certificate generation
│   ├── backup.sh                      # Backup automation
│   ├── restore.sh                     # Restore from backup
│   └── health-check.sh                # Health monitoring
│
├── config/                            # Service configurations
│   ├── prometheus/
│   │   ├── prometheus.yml             # Prometheus config
│   │   └── rules/
│   │       ├── alerts.yml             # Alert rules
│   │       └── recording_rules.yml    # Recording rules
│   │
│   ├── grafana/
│   │   ├── grafana.ini                # Grafana config
│   │   ├── datasources/
│   │   │   └── datasources.yml        # Data source provisioning
│   │   └── dashboards/
│   │       ├── dashboards.yml         # Dashboard provisioning
│   │       ├── system-overview.json   # System dashboard
│   │       ├── application-health.json
│   │       └── security-audit.json
│   │
│   ├── alertmanager/
│   │   ├── alertmanager.yml           # AlertManager config
│   │   └── templates/
│   │       └── email.tmpl             # Email templates
│   │
│   ├── elasticsearch/
│   │   └── elasticsearch.yml          # Elasticsearch config
│   │
│   ├── kibana/
│   │   └── kibana.yml                 # Kibana config
│   │
│   ├── logstash/
│   │   ├── logstash.yml               # Logstash config
│   │   ├── pipelines.yml              # Pipeline definitions
│   │   └── pipeline/
│   │       └── logstash.conf          # Pipeline configuration
│   │
│   └── nginx/
│       ├── nginx.conf                 # Main Nginx config
│       └── conf.d/
│           ├── monitoring.conf        # Monitoring vhost
│           └── ssl.conf               # SSL settings
│
├── nixos/                             # NixOS configurations
│   ├── flake.nix                      # Nix flake
│   ├── flake.lock                     # Dependency lock
│   │
│   ├── server/
│   │   ├── configuration.nix          # Server config
│   │   ├── hardware-configuration.nix # Hardware config
│   │   └── secrets.nix                # SOPS integration
│   │
│   └── client/
│       ├── configuration.nix          # Client config
│       ├── hardware-configuration.nix # Hardware config
│       └── secrets.nix                # SOPS integration
│
├── secrets/                           # Encrypted secrets (SOPS)
│   ├── secrets.yaml                   # Encrypted secrets file
│   ├── age-key.txt                    # Age encryption key (gitignored)
│   └── wireguard/                     # WireGuard keys (gitignored)
│       ├── server-private.key
│       ├── server-public.key
│       ├── client1-private.key
│       └── client1-public.key
│
├── certs/                             # TLS certificates (gitignored)
│   ├── ca.crt                         # CA certificate
│   ├── ca.key                         # CA private key
│   ├── server.crt                     # Server certificate
│   ├── server.key                     # Server private key
│   ├── client1.crt                    # Client certificates
│   └── client1.key
│
├── tests/                             # Testing
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
└── .github/                           # GitHub Actions
    └── workflows/
        ├── ci.yml                     # Continuous Integration
        ├── security-scan.yml          # Security scanning
        └── deploy.yml                 # Deployment automation
```

---

## 🚀 Quick Start Guide

### Prerequisites

1. **Operating System**:
   - Server: NixOS 24.05+ OR Docker-capable Linux
   - Clients: NixOS 24.05+

2. **Software**:
   ```bash
   # On development machine
   sudo apt-get install docker docker-compose openssl age sops git make
   
   # OR on macOS
   brew install docker docker-compose openssl age sops git make
   ```

3. **Resources**:
   - Server: 4GB RAM, 50GB disk minimum
   - Clients: 512MB RAM, 10GB disk minimum

### Step 1: Clone and Setup

```bash
# Clone repository
git clone https://github.com/yourusername/industrial-monitoring-stack.git
cd industrial-monitoring-stack

# Run setup script (generates keys, certs, passwords)
chmod +x scripts/setup.sh
./scripts/setup.sh setup
```

### Step 2: Encrypt Secrets

```bash
# Review generated secrets
cat secrets/secrets-plaintext.yaml

# Configure SOPS with your age key
export SOPS_AGE_KEY_FILE=secrets/age-key.txt

# Encrypt secrets
sops -e secrets/secrets-plaintext.yaml > secrets/secrets.yaml

# Securely delete plaintext
shred -u secrets/secrets-plaintext.yaml
```

### Step 3: Start Monitoring Stack (Docker)

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps

# View logs
docker-compose logs -f

# Initialize Elasticsearch users
./scripts/setup.sh init-es
```

### Step 4: Access Dashboards

```bash
# Get credentials from .env
cat .env | grep PASSWORD

# Open in browser
open https://localhost:5601  # Kibana
open https://localhost:3000  # Grafana
open http://localhost:9090   # Prometheus
```

### Step 5: Deploy Clients (NixOS)

```bash
# On each client machine
sudo nixos-rebuild switch --flake github:yourusername/industrial-monitoring-stack#monitoring-client

# Verify connectivity
sudo wg show
ping 10.100.0.1
```

---

## 🔐 Security Checklist

### Pre-Deployment

- [ ] Change all default passwords in secrets.yaml
- [ ] Generate unique WireGuard keys per client
- [ ] Create site-specific mTLS certificates
- [ ] Review firewall rules in NixOS configs
- [ ] Enable AppArmor profiles
- [ ] Configure fail2ban for SSH protection

### Post-Deployment

- [ ] Verify mTLS is enforcing client certificates
- [ ] Test WireGuard VPN connectivity
- [ ] Confirm HTTPS-only access to dashboards
- [ ] Set up log retention policies
- [ ] Configure AlertManager notification channels
- [ ] Test backup and restore procedures
- [ ] Run security scan: `make security-scan`

---

## 📊 Default Dashboards

### System Overview Dashboard
- CPU/Memory/Disk usage across all hosts
- Network throughput
- Service uptime status
- Alert summary

### Application Health Dashboard
- ExtrusionOS process metrics
- Spectre application status
- Request rates and latencies
- Error rates and traces

### Security Audit Dashboard
- Failed authentication attempts
- Firewall drops
- Unusual network activity
- Certificate expiration warnings

---

## 🔧 Common Operations

### Using Makefile

```bash
# Setup everything
make setup

# Start services
make up

# Stop services
make down

# View logs
make logs SERVICE=elasticsearch

# Restart a service
make restart SERVICE=prometheus

# Backup data
make backup

# Restore from backup
make restore BACKUP_FILE=backup-2025-11-20.tar.gz

# Run health checks
make health

# Security scan
make security-scan

# Update all services
make update
```

### Manual Operations

```bash
# Check service health
curl http://localhost:9200/_cluster/health  # Elasticsearch
curl http://localhost:9090/-/healthy        # Prometheus

# View service logs
docker-compose logs -f --tail=100 grafana

# Access service shell
docker-compose exec elasticsearch bash

# Restart single service
docker-compose restart kibana

# Scale Prometheus
docker-compose up -d --scale prometheus=2
```

---

## 🐛 Troubleshooting

### Elasticsearch Won't Start

```bash
# Check vm.max_map_count
sysctl vm.max_map_count

# Set if needed
sudo sysctl -w vm.max_map_count=262144

# Make permanent
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

### Client Can't Connect via WireGuard

```bash
# On client
sudo wg show
sudo journalctl -u wg-quick-wg0 -f

# Test connectivity
ping 10.100.0.1
curl http://10.100.0.1:9090/-/healthy

# Check firewall
sudo iptables -L -n -v | grep 9100
```

### Certificates Expired

```bash
# Regenerate certificates
./scripts/generate-certs.sh

# Restart Nginx
docker-compose restart nginx
```

### High Memory Usage

```bash
# Check Elasticsearch heap
docker stats elasticsearch

# Adjust heap in docker-compose.yml
# ES_JAVA_OPTS: "-Xms1g -Xmx1g"

# Restart
docker-compose restart elasticsearch
```

---

## 📈 Performance Tuning

### Elasticsearch

```yaml
# docker-compose.yml
elasticsearch:
  environment:
    - "ES_JAVA_OPTS=-Xms4g -Xmx4g"  # Increase heap
  ulimits:
    memlock:
      soft: -1
      hard: -1
```

### Prometheus

```yaml
# config/prometheus/prometheus.yml
global:
  scrape_interval: 30s  # Reduce from 15s for less load
  evaluation_interval: 30s
```

### Filebeat

```yaml
# NixOS client config
services.filebeat.settings = {
  queue.mem = {
    events = 8192;  # Increase buffer
    flush.min_events = 4096;
  };
  output.logstash = {
    compression_level = 5;  # More compression
    bulk_max_size = 4096;   # Larger batches
  };
};
```

---

## 🔄 Backup & Disaster Recovery

### Automated Backups

```bash
# Setup cron job
crontab -e

# Add daily backup at 2 AM
0 2 * * * /opt/monitoring/scripts/backup.sh
```

### Manual Backup

```bash
# Backup all data
./scripts/backup.sh

# Backup specific service
docker-compose exec elasticsearch curl -X PUT "localhost:9200/_snapshot/backup/snapshot_1?wait_for_completion=true"
```

### Restore

```bash
# Stop services
docker-compose down

# Restore data
./scripts/restore.sh backup-2025-11-20.tar.gz

# Start services
docker-compose up -d
```

---

## 🌐 Production Deployment

### Using Kubernetes (Bonus)

```bash
# Convert to K8s manifests
kompose convert -f docker-compose.yml

# Deploy to cluster
kubectl apply -f ./k8s/

# Setup Ingress for HTTPS
kubectl apply -f k8s/ingress.yaml
```

### Using Terraform (Bonus)

```bash
# Initialize Terraform
cd terraform/
terraform init

# Plan deployment
terraform plan -out=plan.tfplan

# Apply
terraform apply plan.tfplan
```

---

## 📝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📜 License

MIT License - see [LICENSE](LICENSE)

---

## 🆘 Support

- Documentation: https://github.com/AlexanderMonsanto/riefenhaeuser-nixos-elk/wiki
- Issues: https://github.com/yourusername/riefenhaeuser-nixos-elk/issues
- Email: alexandermonsanto@gmail.com

---

**Built for Reifenhäuser Next - Industrial 4.0 Excellence**
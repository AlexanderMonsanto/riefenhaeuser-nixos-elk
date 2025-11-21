#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Generating Kubernetes Secrets...${NC}"

# Check if secrets.yaml already exists
if [ -f "k8s/secrets/secrets.yaml" ]; then
    echo -e "${YELLOW}Warning: k8s/secrets/secrets.yaml already exists!${NC}"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# Generate random passwords
ELASTIC_PASSWORD=$(openssl rand -base64 32)
KIBANA_SYSTEM_PASSWORD=$(openssl rand -base64 32)
LOGSTASH_SYSTEM_PASSWORD=$(openssl rand -base64 32)
GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 32)
KIBANA_ENCRYPTION_KEY=$(openssl rand -base64 32)
KIBANA_SECURITY_KEY=$(openssl rand -base64 32)
KIBANA_REPORTING_KEY=$(openssl rand -base64 32)

# Create secrets file
# Resolve project root (assuming script is in scripts/ directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SECRETS_DIR="$PROJECT_ROOT/k8s/secrets"

mkdir -p "$SECRETS_DIR"

# Create secrets file
cat <<EOF > "$SECRETS_DIR/secrets.yaml"
apiVersion: v1
kind: Secret
metadata:
  name: monitoring-secrets
  namespace: monitoring
type: Opaque
stringData:
  # Elasticsearch
  elastic-password: "${ELASTIC_PASSWORD}"
  
  # Kibana
  kibana-system-password: "${KIBANA_SYSTEM_PASSWORD}"
  kibana-encryption-key: "${KIBANA_ENCRYPTION_KEY}"
  kibana-security-key: "${KIBANA_SECURITY_KEY}"
  kibana-reporting-key: "${KIBANA_REPORTING_KEY}"
  
  # Logstash
  logstash-system-password: "${LOGSTASH_SYSTEM_PASSWORD}"
  
  # Grafana
  grafana-admin-user: "admin"
  grafana-admin-password: "${GRAFANA_ADMIN_PASSWORD}"
EOF

echo -e "${GREEN}✓ Secrets generated successfully!${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC}"
echo "1. Secrets saved to: k8s/secrets/secrets.yaml"
echo "2. This file is gitignored and will NOT be committed"
echo "3. Save these credentials securely:"
echo ""
echo -e "${GREEN}Elasticsearch:${NC}"
echo "  Username: elastic"
echo "  Password: ${ELASTIC_PASSWORD}"
echo ""
echo -e "${GREEN}Grafana:${NC}"
echo "  Username: admin"
echo "  Password: ${GRAFANA_ADMIN_PASSWORD}"
echo ""
echo -e "${YELLOW}To encrypt with SOPS:${NC}"
echo "  sops -e k8s/secrets/secrets.yaml > k8s/secrets/secrets.enc.yaml"
echo ""
echo -e "${YELLOW}To apply to Kubernetes:${NC}"
echo "  kubectl apply -f k8s/secrets/secrets.yaml"

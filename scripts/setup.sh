#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Initializing Industrial Monitoring Stack...${NC}"

# Create directories
mkdir -p secrets certs config/nginx/conf.d

# Generate secrets if not exists
if [ ! -f secrets/secrets-plaintext.yaml ]; then
    echo "Generating initial secrets..."
    cat <<EOF > secrets/secrets-plaintext.yaml
elastic_password: $(openssl rand -base64 16)
kibana_system_password: $(openssl rand -base64 16)
logstash_system_password: $(openssl rand -base64 16)
grafana_admin_password: $(openssl rand -base64 16)
kibana_encryption_key: $(openssl rand -base64 32)
kibana_security_key: $(openssl rand -base64 32)
kibana_reporting_key: $(openssl rand -base64 32)
EOF
    echo "Secrets template created at secrets/secrets-plaintext.yaml"
fi

# Generate .env if not exists
if [ ! -f .env ]; then
    echo "Generating .env file..."
    cat <<EOF > .env
ELASTIC_PASSWORD=$(openssl rand -base64 16)
KIBANA_SYSTEM_PASSWORD=$(openssl rand -base64 16)
LOGSTASH_SYSTEM_PASSWORD=$(openssl rand -base64 16)
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 16)
KIBANA_ENCRYPTION_KEY=$(openssl rand -base64 32)
KIBANA_SECURITY_KEY=$(openssl rand -base64 32)
KIBANA_REPORTING_KEY=$(openssl rand -base64 32)
EOF
    echo ".env file created with secure random passwords."
fi

# Generate WireGuard keys
if [ ! -f secrets/wireguard/server-private.key ]; then
    echo "Generating WireGuard keys..."
    mkdir -p secrets/wireguard
    wg genkey | tee secrets/wireguard/server-private.key | wg pubkey > secrets/wireguard/server-public.key
    wg genkey | tee secrets/wireguard/client1-private.key | wg pubkey > secrets/wireguard/client1-public.key
fi

# Generate Certificates
if [ ! -f certs/ca.key ]; then
    echo "Generating certificates..."
    ./scripts/generate-certs.sh
fi

echo -e "${GREEN}Setup complete!${NC}"
echo "Please encrypt your secrets using SOPS and update .env file."

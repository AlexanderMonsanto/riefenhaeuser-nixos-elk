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

# Set up Elasticsearch built-in user passwords
echo "Setting up Elasticsearch user passwords..."
echo "Waiting for Elasticsearch to be ready..."

# Start Elasticsearch if not running
docker-compose up -d elasticsearch

# Wait for Elasticsearch to be healthy
MAX_WAIT=60
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    if docker-compose ps elasticsearch | grep -q "Up (healthy)"; then
        echo "Elasticsearch is healthy"
        break
    fi
    echo "Waiting for Elasticsearch... ($ELAPSED/$MAX_WAIT seconds)"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo "Warning: Elasticsearch did not become healthy in time. You may need to set passwords manually."
else
    # Load passwords from .env
    source .env

    # Set kibana_system password
    echo "Setting kibana_system password..."
    docker exec elasticsearch curl -s -X POST -u "elastic:${ELASTIC_PASSWORD}" \
        -H "Content-Type: application/json" \
        "http://localhost:9200/_security/user/kibana_system/_password" \
        -d "{\"password\":\"${KIBANA_SYSTEM_PASSWORD}\"}" || echo "Warning: Failed to set kibana_system password"

    # Set logstash_system password
    echo "Setting logstash_system password..."
    docker exec elasticsearch curl -s -X POST -u "elastic:${ELASTIC_PASSWORD}" \
        -H "Content-Type: application/json" \
        "http://localhost:9200/_security/user/logstash_system/_password" \
        -d "{\"password\":\"${LOGSTASH_SYSTEM_PASSWORD}\"}" || echo "Warning: Failed to set logstash_system password"

    echo "Elasticsearch user passwords configured successfully"
fi

echo -e "${GREEN}Setup complete!${NC}"
echo "Please encrypt your secrets using SOPS and update .env file."
echo "Run 'docker-compose up -d' to start all services."

# Makefile for Industrial Monitoring Stack
# Usage: make [target]

.PHONY: help setup up down restart logs status health backup restore clean security-scan update

# Default target
.DEFAULT_GOAL := help

# Variables
COMPOSE := docker-compose
BACKUP_DIR := ./backups
DATE := $(shell date +%Y%m%d_%H%M%S)

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

##@ General

help: ## Display this help message
	@echo "$(GREEN)Industrial Monitoring Stack - Available Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make $(YELLOW)<target>$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Setup & Initialization

setup: ## Run initial setup (generate keys, certs, secrets)
	@echo "$(GREEN)Running initial setup...$(NC)"
	@chmod +x scripts/setup.sh
	@./scripts/setup.sh setup
	@echo "$(GREEN)Setup complete! Run 'make up' to start services.$(NC)"

init-secrets: ## Initialize and encrypt secrets with SOPS
	@echo "$(GREEN)Encrypting secrets...$(NC)"
	@if [ ! -f secrets/age-key.txt ]; then \
		echo "$(RED)Error: Age key not found. Run 'make setup' first.$(NC)"; \
		exit 1; \
	fi
	@export SOPS_AGE_KEY_FILE=secrets/age-key.txt && \
		sops -e secrets/secrets-plaintext.yaml > secrets/secrets.yaml
	@shred -u secrets/secrets-plaintext.yaml || rm -f secrets/secrets-plaintext.yaml
	@echo "$(GREEN)Secrets encrypted and plaintext removed.$(NC)"

init-es: ## Initialize Elasticsearch users and passwords
	@echo "$(GREEN)Initializing Elasticsearch...$(NC)"
	@./scripts/setup.sh init-es
	@echo "$(GREEN)Elasticsearch initialized.$(NC)"

##@ Service Management

up: ## Start all services
	@echo "$(GREEN)Starting all services...$(NC)"
	@$(COMPOSE) up -d
	@echo "$(GREEN)Services started. Run 'make status' to check health.$(NC)"

down: ## Stop all services
	@echo "$(YELLOW)Stopping all services...$(NC)"
	@$(COMPOSE) down
	@echo "$(GREEN)Services stopped.$(NC)"

restart: ## Restart all services
	@echo "$(YELLOW)Restarting all services...$(NC)"
	@$(COMPOSE) restart
	@echo "$(GREEN)Services restarted.$(NC)"

restart-service: ## Restart a specific service (usage: make restart-service SERVICE=elasticsearch)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE not specified. Usage: make restart-service SERVICE=elasticsearch$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Restarting $(SERVICE)...$(NC)"
	@$(COMPOSE) restart $(SERVICE)
	@echo "$(GREEN)$(SERVICE) restarted.$(NC)"

stop-service: ## Stop a specific service (usage: make stop-service SERVICE=kibana)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE not specified.$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Stopping $(SERVICE)...$(NC)"
	@$(COMPOSE) stop $(SERVICE)

start-service: ## Start a specific service (usage: make start-service SERVICE=kibana)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE not specified.$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Starting $(SERVICE)...$(NC)"
	@$(COMPOSE) start $(SERVICE)

##@ Monitoring & Debugging

status: ## Show status of all services
	@echo "$(GREEN)Service Status:$(NC)"
	@$(COMPOSE) ps

logs: ## View logs for all services (usage: make logs SERVICE=grafana)
	@if [ -z "$(SERVICE)" ]; then \
		$(COMPOSE) logs -f --tail=100; \
	else \
		$(COMPOSE) logs -f --tail=100 $(SERVICE); \
	fi

logs-all: ## View all logs without following
	@$(COMPOSE) logs --tail=200

health: ## Check health of all services
	@echo "$(GREEN)Checking service health...$(NC)"
	@echo ""
	@echo "Elasticsearch:"
	@curl -s http://localhost:9200/_cluster/health?pretty || echo "$(RED)❌ Not responding$(NC)"
	@echo ""
	@echo "Kibana:"
	@curl -s http://localhost:5601/api/status | jq -r '.status.overall.state' || echo "$(RED)❌ Not responding$(NC)"
	@echo ""
	@echo "Prometheus:"
	@curl -s http://localhost:9090/-/healthy || echo "$(RED)❌ Not responding$(NC)"
	@echo ""
	@echo "Grafana:"
	@curl -s http://localhost:3000/api/health | jq -r '.status' || echo "$(RED)❌ Not responding$(NC)"
	@echo ""
	@echo "AlertManager:"
	@curl -s http://localhost:9093/-/healthy || echo "$(RED)❌ Not responding$(NC)"

stats: ## Show resource usage statistics
	@echo "$(GREEN)Resource Usage:$(NC)"
	@docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

shell: ## Access shell of a service (usage: make shell SERVICE=elasticsearch)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)Error: SERVICE not specified. Usage: make shell SERVICE=elasticsearch$(NC)"; \
		exit 1; \
	fi
	@$(COMPOSE) exec $(SERVICE) /bin/bash || $(COMPOSE) exec $(SERVICE) /bin/sh

##@ Data Management

backup: ## Create backup of all data volumes
	@echo "$(GREEN)Creating backup...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@chmod +x scripts/backup.sh
	@./scripts/backup.sh
	@echo "$(GREEN)Backup created in $(BACKUP_DIR)$(NC)"

restore: ## Restore from backup (usage: make restore BACKUP_FILE=backup-2025-11-20.tar.gz)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo "$(RED)Error: BACKUP_FILE not specified.$(NC)"; \
		echo "Usage: make restore BACKUP_FILE=backup-2025-11-20.tar.gz"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Restoring from $(BACKUP_FILE)...$(NC)"
	@chmod +x scripts/restore.sh
	@./scripts/restore.sh $(BACKUP_FILE)
	@echo "$(GREEN)Restore complete.$(NC)"

list-backups: ## List available backups
	@echo "$(GREEN)Available backups:$(NC)"
	@ls -lh $(BACKUP_DIR)/ 2>/dev/null || echo "No backups found"

##@ Security

security-scan: ## Run security vulnerability scan
	@echo "$(GREEN)Running security scan...$(NC)"
	@echo "Scanning Docker images..."
	@for img in $$($(COMPOSE) config | grep 'image:' | awk '{print $$2}'); do \
		echo "$(YELLOW)Scanning $$img$(NC)"; \
		docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image $$img; \
	done
	@echo "$(GREEN)Security scan complete.$(NC)"

check-secrets: ## Verify secrets are encrypted
	@echo "$(GREEN)Checking secrets encryption...$(NC)"
	@if [ -f secrets/secrets-plaintext.yaml ]; then \
		echo "$(RED)❌ WARNING: Plaintext secrets file exists!$(NC)"; \
		exit 1; \
	else \
		echo "$(GREEN)✓ No plaintext secrets found$(NC)"; \
	fi
	@if [ -f secrets/secrets.yaml ]; then \
		if grep -q "sops:" secrets/secrets.yaml; then \
			echo "$(GREEN)✓ Secrets are encrypted with SOPS$(NC)"; \
		else \
			echo "$(RED)❌ secrets.yaml is not encrypted!$(NC)"; \
			exit 1; \
		fi \
	else \
		echo "$(YELLOW)⚠ secrets.yaml not found$(NC)"; \
	fi

rotate-keys: ## Rotate WireGuard keys
	@echo "$(YELLOW)Rotating WireGuard keys...$(NC)"
	@chmod +x scripts/generate-certs.sh
	@./scripts/generate-certs.sh rotate
	@echo "$(GREEN)Keys rotated. Update client configurations.$(NC)"

##@ Maintenance

update: ## Update all service images
	@echo "$(GREEN)Pulling latest images...$(NC)"
	@$(COMPOSE) pull
	@echo "$(GREEN)Recreating services with new images...$(NC)"
	@$(COMPOSE) up -d
	@echo "$(GREEN)Update complete.$(NC)"

prune: ## Remove unused Docker resources
	@echo "$(YELLOW)Pruning Docker resources...$(NC)"
	@docker system prune -f
	@echo "$(GREEN)Prune complete.$(NC)"

clean: ## Stop services and remove volumes (WARNING: destructive!)
	@echo "$(RED)WARNING: This will remove all data!$(NC)"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
	@sleep 5
	@$(COMPOSE) down -v
	@echo "$(GREEN)Cleanup complete.$(NC)"

clean-logs: ## Remove old log files
	@echo "$(YELLOW)Cleaning old logs...$(NC)"
	@find ./logs -name "*.log" -mtime +30 -delete 2>/dev/null || true
	@echo "$(GREEN)Old logs removed.$(NC)"

##@ Testing

test-alerts: ## Test alert configuration
	@echo "$(GREEN)Testing alert rules...$(NC)"
	@docker run --rm -v $$(pwd)/config/prometheus/rules:/rules:ro prom/promtool check rules /rules/*.yml
	@echo "$(GREEN)Alert rules validation complete.$(NC)"

test-prometheus: ## Validate Prometheus configuration
	@echo "$(GREEN)Validating Prometheus config...$(NC)"
	@docker run --rm -v $$(pwd)/config/prometheus:/config:ro prom/promtool check config /config/prometheus.yml
	@echo "$(GREEN)Prometheus config is valid.$(NC)"

test-connectivity: ## Test connectivity to all client sites
	@echo "$(GREEN)Testing client connectivity...$(NC)"
	@for ip in 10.100.0.10 10.100.0.11 10.100.0.12; do \
		echo -n "Testing $$ip: "; \
		ping -c 1 -W 2 $$ip > /dev/null 2>&1 && echo "$(GREEN)✓$(NC)" || echo "$(RED)✗$(NC)"; \
	done

##@ Documentation

docs: ## Generate documentation
	@echo "$(GREEN)Generating documentation...$(NC)"
	@if command -v mkdocs > /dev/null; then \
		mkdocs build; \
		echo "$(GREEN)Documentation generated in site/$(NC)"; \
	else \
		echo "$(YELLOW)mkdocs not installed. Install with: pip install mkdocs$(NC)"; \
	fi

serve-docs: ## Serve documentation locally
	@if command -v mkdocs > /dev/null; then \
		mkdocs serve; \
	else \
		echo "$(YELLOW)mkdocs not installed. Install with: pip install mkdocs$(NC)"; \
	fi

##@ Development

dev: ## Start in development mode with hot reload
	@echo "$(GREEN)Starting in development mode...$(NC)"
	@$(COMPOSE) -f docker-compose.yml -f docker-compose.dev.yml up

format: ## Format configuration files
	@echo "$(GREEN)Formatting YAML files...$(NC)"
	@find config/ -name "*.yml" -o -name "*.yaml" | xargs -I {} sh -c 'prettier --write {} || true'

validate: ## Validate all configuration files
	@echo "$(GREEN)Validating configurations...$(NC)"
	@$(MAKE) test-prometheus
	@$(MAKE) test-alerts
	@echo "$(GREEN)All validations passed.$(NC)"

##@ Quick Access

kibana: ## Open Kibana in browser
	@echo "$(GREEN)Opening Kibana...$(NC)"
	@open http://localhost:5601 || xdg-open http://localhost:5601 2>/dev/null || echo "Open http://localhost:5601 in your browser"

grafana: ## Open Grafana in browser
	@echo "$(GREEN)Opening Grafana...$(NC)"
	@open http://localhost:3000 || xdg-open http://localhost:3000 2>/dev/null || echo "Open http://localhost:3000 in your browser"

prometheus: ## Open Prometheus in browser
	@echo "$(GREEN)Opening Prometheus...$(NC)"
	@open http://localhost:9090 || xdg-open http://localhost:9090 2>/dev/null || echo "Open http://localhost:9090 in your browser"

alertmanager: ## Open AlertManager in browser
	@echo "$(GREEN)Opening AlertManager...$(NC)"
	@open http://localhost:9093 || xdg-open http://localhost:9093 2>/dev/null || echo "Open http://localhost:9093 in your browser"

##@ Information

version: ## Show version information
	@echo "$(GREEN)Version Information:$(NC)"
	@echo "Docker Compose: $$(docker-compose --version)"
	@echo "Docker: $$(docker --version)"
	@echo ""
	@echo "Service Versions:"
	@$(COMPOSE) config | grep 'image:' | sort -u

ports: ## Show all exposed ports
	@echo "$(GREEN)Exposed Ports:$(NC)"
	@echo "Kibana:        5601"
	@echo "Grafana:       3000"
	@echo "Prometheus:    9090"
	@echo "AlertManager:  9093"
	@echo "Elasticsearch: 9200"
	@echo "Logstash:      5044"
	@echo "Node Exporter: 9100"
	@echo "Nginx:         80, 443"

config: ## Show current configuration
	@echo "$(GREEN)Current Configuration:$(NC)"
	@$(COMPOSE) config

##@ Aliases (shortcuts)

start: up ## Alias for 'up'
stop: down ## Alias for 'down'
ps: status ## Alias for 'status'
log: logs ## Alias for 'logs'
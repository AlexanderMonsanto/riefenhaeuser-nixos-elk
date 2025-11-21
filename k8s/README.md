# Kubernetes Deployment Guide

This directory contains Kubernetes manifests for deploying the Industrial Monitoring Stack on Kubernetes or K3s.

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Options](#deployment-options)
- [Configuration](#configuration)
- [Accessing Services](#accessing-services)
- [Scaling](#scaling)
- [Troubleshooting](#troubleshooting)
- [Migration from Docker Compose](#migration-from-docker-compose)

---

## 🎯 Why Kubernetes?

### Production-Grade Features
- ✅ **High Availability** - Multi-replica deployments with automatic failover
- ✅ **Auto-Scaling** - Horizontal Pod Autoscaling based on metrics
- ✅ **Rolling Updates** - Zero-downtime deployments
- ✅ **Self-Healing** - Automatic restart of failed containers
- ✅ **Resource Management** - CPU/Memory limits and requests
- ✅ **Service Discovery** - Built-in DNS for service communication
- ✅ **Load Balancing** - Automatic traffic distribution

### When to Use Kubernetes vs Docker Compose

| Feature | Docker Compose | Kubernetes |
|---------|----------------|------------|
| **Complexity** | Simple | Moderate |
| **Setup Time** | Minutes | 10-30 minutes |
| **Best For** | Development, Testing | Production, Multi-node |
| **High Availability** | ❌ No | ✅ Yes |
| **Auto-Scaling** | ❌ No | ✅ Yes |
| **Rolling Updates** | ❌ No | ✅ Yes |
| **Resource Limits** | Basic | Advanced |
| **Multi-Node** | ❌ No | ✅ Yes |

**Recommendation:**
- **Development/Testing:** Use Docker Compose
- **Production/Multi-Site:** Use Kubernetes/K3s

---

## 📦 Prerequisites

### For Standard Kubernetes
```bash
# Kubernetes cluster (1.24+)
kubectl version --client

# Kustomize (optional, kubectl has built-in support)
kustomize version
```

### For K3s (Lightweight Kubernetes)
```bash
# Install K3s on NixOS (see nixos/server/configuration.nix)
# Or install manually:
curl -sfL https://get.k3s.io | sh -
```

### Storage
- K3s: Uses `local-path` provisioner (automatic)
- Other K8s: Ensure you have a StorageClass configured

---

## 🚀 Quick Start

### 1. Create Secrets

**Option A: Manual**
```bash
# Edit the secrets file
cp k8s/secrets/secrets.yaml k8s/secrets/secrets-local.yaml
# Edit secrets-local.yaml with your passwords
kubectl apply -f k8s/secrets/secrets-local.yaml
```

**Option B: SOPS (Recommended)**
```bash
# Encrypt secrets
sops -e k8s/secrets/secrets.yaml > k8s/secrets/secrets.enc.yaml

# Decrypt and apply
sops -d k8s/secrets/secrets.enc.yaml | kubectl apply -f -
```

### 2. Deploy the Stack

```bash
# Deploy everything with Kustomize
kubectl apply -k k8s/

# Or without Kustomize
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmaps/
kubectl apply -f k8s/pvcs/
kubectl apply -f k8s/deployments/
kubectl apply -f k8s/services/
```

### 3. Verify Deployment

```bash
# Check all pods
kubectl get pods -n monitoring

# Watch pod status
kubectl get pods -n monitoring -w

# Check services
kubectl get svc -n monitoring
```

---

## 🔧 Configuration

### Resource Limits

Default resource allocations:

| Service | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------|-------------|-----------|----------------|--------------|
| Elasticsearch | 500m | 2000m | 2Gi | 4Gi |
| Kibana | 250m | 1000m | 512Mi | 1Gi |
| Logstash | 500m | 1000m | 1Gi | 2Gi |
| Prometheus | 500m | 1000m | 1Gi | 2Gi |
| Grafana | 100m | 500m | 256Mi | 512Mi |
| Alertmanager | 50m | 200m | 128Mi | 256Mi |
| Node Exporter | 50m | 200m | 64Mi | 128Mi |

**Total Minimum:** ~2 CPU cores, ~5Gi RAM  
**Recommended:** 4+ CPU cores, 8+ Gi RAM

### Storage

Default PVC sizes:
- Elasticsearch: 10Gi
- Prometheus: 20Gi
- Grafana: 2Gi
- Logstash: 5Gi

**Total:** 37Gi

To modify, edit `k8s/pvcs/storage.yaml`

---

## 🌐 Accessing Services

### Port Forwarding (Development)

```bash
# Elasticsearch
kubectl port-forward -n monitoring svc/elasticsearch 9200:9200

# Kibana
kubectl port-forward -n monitoring svc/kibana 5601:5601

# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000

# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Alertmanager
kubectl port-forward -n monitoring svc/alertmanager 9093:9093
```

### NodePort (K3s/Single Node)

Edit services to use `type: NodePort`:
```yaml
spec:
  type: NodePort
  ports:
  - port: 3000
    nodePort: 30300  # Access via http://node-ip:30300
```

### Ingress (Production)

Create an Ingress resource (example for Nginx Ingress):
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: monitoring-ingress
  namespace: monitoring
spec:
  rules:
  - host: grafana.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: grafana
            port:
              number: 3000
```

---

## 📈 Scaling

### Horizontal Scaling

```bash
# Scale Grafana to 3 replicas
kubectl scale deployment grafana -n monitoring --replicas=3

# Scale Kibana
kubectl scale deployment kibana -n monitoring --replicas=2
```

### Elasticsearch Cluster

To run Elasticsearch in cluster mode:
1. Edit `k8s/deployments/elasticsearch.yaml`
2. Change `discovery.type` from `single-node` to `zen`
3. Increase `replicas` to 3
4. Add proper cluster configuration

### Auto-Scaling (HPA)

```bash
# Create HPA for Grafana
kubectl autoscale deployment grafana -n monitoring \
  --cpu-percent=70 \
  --min=1 \
  --max=5
```

---

## 🔍 Troubleshooting

### Check Pod Logs

```bash
# View logs
kubectl logs -n monitoring <pod-name>

# Follow logs
kubectl logs -n monitoring <pod-name> -f

# Previous container logs (if crashed)
kubectl logs -n monitoring <pod-name> --previous
```

### Describe Resources

```bash
# Get detailed pod information
kubectl describe pod -n monitoring <pod-name>

# Check events
kubectl get events -n monitoring --sort-by='.lastTimestamp'
```

### Common Issues

#### Pods Pending
```bash
# Check PVC status
kubectl get pvc -n monitoring

# Check node resources
kubectl top nodes
```

#### ImagePullBackOff
```bash
# Check image pull status
kubectl describe pod -n monitoring <pod-name>
```

#### CrashLoopBackOff
```bash
# Check logs
kubectl logs -n monitoring <pod-name> --previous

# Check resource limits
kubectl describe pod -n monitoring <pod-name>
```

---

## 🔄 Migration from Docker Compose

### 1. Export Data (Optional)

```bash
# Backup Docker volumes
docker run --rm -v reifenhaeuser-nixos-elk_elasticsearch-data:/data \
  -v $(pwd)/backup:/backup alpine \
  tar czf /backup/elasticsearch-data.tar.gz /data
```

### 2. Deploy Kubernetes Stack

```bash
kubectl apply -k k8s/
```

### 3. Import Data (Optional)

```bash
# Copy backup to pod
kubectl cp backup/elasticsearch-data.tar.gz \
  monitoring/elasticsearch-0:/tmp/

# Extract in pod
kubectl exec -n monitoring elasticsearch-0 -- \
  tar xzf /tmp/elasticsearch-data.tar.gz -C /usr/share/elasticsearch/data
```

### 4. Verify

```bash
# Check cluster health
kubectl port-forward -n monitoring svc/elasticsearch 9200:9200
curl -u elastic:password http://localhost:9200/_cluster/health
```

---

## 🧹 Cleanup

```bash
# Delete everything
kubectl delete -k k8s/

# Or delete namespace (removes everything)
kubectl delete namespace monitoring
```

---

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [K3s Documentation](https://docs.k3s.io/)
- [Kustomize Documentation](https://kustomize.io/)
- [Elastic on Kubernetes](https://www.elastic.co/guide/en/cloud-on-k8s/current/index.html)
- [Prometheus Operator](https://prometheus-operator.dev/)

---

## 🆘 Support

For issues specific to this deployment:
1. Check logs: `kubectl logs -n monitoring <pod-name>`
2. Check events: `kubectl get events -n monitoring`
3. Review main [README.md](../README.md)
4. Check [troubleshooting.md](../docs/troubleshooting.md)

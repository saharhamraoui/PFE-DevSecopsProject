# Monitoring — Prometheus + Grafana

## Production (AKS)

Monitoring is deployed on AKS via the `kube-prometheus-stack` Helm chart in the `monitoring` namespace.

### Deployed components
| Component | Description |
|---|---|
| Prometheus | Metrics collection, 7-day retention |
| Grafana | Dashboards (admin / PFEAdmin2024!) |
| kube-state-metrics | Kubernetes object metrics |
| node-exporter | Node-level CPU / memory / disk |
| Prometheus Operator | CRD-based configuration |

### Access Grafana (port-forward)

```bash
# Set proxy bypass for AKS endpoint
export NO_PROXY="*.hcp.eastus.azmk8s.io"

# Get credentials
az aks get-credentials --resource-group sahar-rg --name sahar-aks

# Forward Grafana to localhost:3000
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
```

Then open **http://localhost:3000** — login: `admin` / `PFEAdmin2024!`

### Key dashboards (pre-loaded)
- **Kubernetes / Compute Resources / Cluster** — cluster-wide CPU & memory
- **Kubernetes / Compute Resources / Pod** — per-pod metrics
- **Node Exporter / Nodes** — node CPU, memory, disk, network
- **Kubernetes / Networking** — pod network traffic

### Helm management

```bash
# List releases
helm list -n monitoring

# Upgrade (e.g., change retention)
helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.retention=14d \
  --reuse-values

# Uninstall
helm uninstall kube-prometheus-stack -n monitoring
```

---

## Local development (docker-compose)

A minimal Prometheus + Grafana stack for local development:

```bash
docker-compose up -d
```

- Prometheus: http://localhost:9090
- Grafana: http://localhost:3000 (admin/admin)

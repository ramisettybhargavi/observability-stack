#!/bin/bash
set -euo pipefail

# Delete all namespaces used by the observability stack and apps
kubectl delete namespace monitoring || true
kubectl delete namespace logging || true
kubectl delete namespace tracing || true
kubectl delete namespace chaos-engineering || true

# Optionally delete Helm releases (if Helm manages the namespaces)
helm uninstall prometheus -n monitoring || true
helm uninstall elasticsearch -n logging || true
helm uninstall kibana -n logging || true
helm uninstall filebeat -n logging || true
helm uninstall jaeger -n tracing || true
helm uninstall otel-collector -n tracing || true

# Clean up Terraform state (optional)
cd terraform
terraform destroy -auto-approve

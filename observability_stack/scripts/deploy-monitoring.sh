#!/bin/bash
set -euo pipefail

# Create monitoring namespace
kubectl create namespace monitoring || true

# Add Prometheus Helm chart repository and update
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Deploy Prometheus stack with custom values
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f k8s/monitoring/prometheus-values.yaml

# Apply custom alert rules
kubectl apply -f k8s/monitoring/custom-alerts.yaml

# Wait for all pods to be ready
kubectl wait --for=condition=Ready pods --all -n monitoring --timeout=10m

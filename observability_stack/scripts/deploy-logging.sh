#!/bin/bash
set -euo pipefail

# Create logging namespace
kubectl create namespace logging || true

# Add Elastic Helm chart repository and update
helm repo add elastic https://helm.elastic.co
helm repo update

# Deploy Elasticsearch
helm upgrade --install elasticsearch elastic/elasticsearch \
  -n logging \
  -f k8s/logging/elasticsearch-values.yaml

# Wait for Elasticsearch pods to be ready
kubectl wait --for=condition=Ready pods -l app=elasticsearch -n logging --timeout=20m

# Deploy Kibana
helm upgrade --install kibana elastic/kibana \
  -n logging \
  -f k8s/logging/kibana-values.yaml

# Deploy Filebeat
helm upgrade --install filebeat elastic/filebeat \
  -n logging \
  -f k8s/logging/filebeat-values.yaml

# Wait for Kibana and Filebeat to be ready
kubectl wait --for=condition=Ready pods -l app=kibana -n logging --timeout=10m
kubectl wait --for=condition=Ready pods -l app=filebeat -n logging --timeout=10m

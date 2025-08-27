#!/bin/bash
set -euo pipefail

# Create tracing namespace
kubectl create namespace tracing || true

# Add Helm repositories
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

# Deploy Jaeger
helm upgrade --install jaeger jaegertracing/jaeger \
  -n tracing \
  -f k8s/tracing/jaeger-values.yaml

# Deploy OpenTelemetry Collector
helm upgrade --install otel-collector open-telemetry/opentelemetry-collector \
  -n tracing \
  -f k8s/tracing/otel-collector-values.yaml

# Wait for all tracing components to be ready
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=jaeger -n tracing --timeout=10m
kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=opentelemetry-collector -n tracing --timeout=10m

#!/bin/bash
set -euo pipefail

# Setup environment variables
export AWS_REGION=us-west-2
export CLUSTER_NAME=observability-cluster

# Initialize Terraform and provision infrastructure
cd terraform
terraform init
terraform apply -auto-approve

# Update kubeconfig for kubectl access
aws eks --region $AWS_REGION update-kubeconfig --name $CLUSTER_NAME

# Verify cluster nodes
kubectl get nodes

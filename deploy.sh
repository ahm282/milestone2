#!/bin/bash

# Apply Apache YAMLs
kubectl apply -f apache/apache-deployment.yaml
kubectl apply -f apache/apache-service.yaml
kubectl apply -f apache/apache-ingress.yaml

# Apply API YAMLs
kubectl apply -f api/api-deployment.yaml
kubectl apply -f api/api-service.yaml
kubectl apply -f api/api-ingress.yaml

# Apply Postgres YAMLs
kubectl apply -f postgres/postgres-deployment.yaml
kubectl apply -f postgres/postgres-ingress.yaml

# Deploy Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install my-prometheus prometheus-community/prometheus --version 25.8.1 -f prometheus/values.yaml

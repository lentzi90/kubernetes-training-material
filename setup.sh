#!/bin/bash

helm version

./scripts/initialize-cluster.sh certs

source scripts/helm-env.sh certs/kube-system/certs

helm version

# helm upgrade --install prom-operator stable/prometheus-operator \
#     --namespace monitoring --version 6.8.0

helm upgrade --install blue-green charts/blue-green --namespace blue-green -f values/blue-green-v1.yaml

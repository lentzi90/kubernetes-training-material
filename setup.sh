#!/bin/bash

helm version

./scripts/initialize-cluster.sh certs

source scripts/helm-env.sh certs

helm version

helm upgrade --install prom-operator stable/prometheus-operator \
    --namespace monitoring --version 6.8.0

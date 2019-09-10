#!/bin/bash

# Script for setting up env vars with TLS options for helm.
#
# Usage: source helm-env.sh [cert-dir] [client-prefix] [namespace]
# helm list
#
# Defaults:
# - cert-dir: ./certs
# - client prefix: helm
# - namespace: kube-system

CERT_DIR=${1:-$(pwd)/certs}
CLIENT_PREFIX=${2:-helm}
NAMESPACE=${3:-kube-system}

export TILLER_NAMESPACE=$NAMESPACE

export HELM_TLS_CA_CERT="${CERT_DIR}/ca.pem"
export HELM_TLS_CERT="${CERT_DIR}/${CLIENT_PREFIX}.pem"
export HELM_TLS_KEY="${CERT_DIR}/${CLIENT_PREFIX}-key.pem"
export HELM_TLS_ENABLE=true

# This seems problematic
# https://github.com/helm/helm/issues/4755
# export HELM_TLS_VERIFY=true

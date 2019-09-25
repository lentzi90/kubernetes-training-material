#!/bin/bash

# helm version
#
# ./scripts/initialize-cluster.sh certs
#
# source scripts/helm-env.sh certs/kube-system/certs
#
# helm version

# Storage class
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: default
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: kubernetes.io/aws-ebs
EOF

# Secret used by kube-backup
kubectl create secret generic kube-backup-ssh -n kube-system --from-file=id_rsa=.ssh/id_rsa --from-file=known_hosts=.ssh/known_hosts

# Cluster wide tiller
kubectl -n kube-system create sa tiller
kubectl create clusterrolebinding tiller --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
# Insecure tiller, just for demo
helm init --service-account=tiller --history-max 200
# Wait for tiller to start
kubectl rollout status deployment tiller-deploy -n kube-system

kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/alertmanager.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheus.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheusrule.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/servicemonitor.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/podmonitor.crd.yaml

helm upgrade --install prom-operator stable/prometheus-operator \
    --set alertmanager.config.global.slack_api_url=$(pass Udda/slack-demo-hook) \
    -f values/prometheus-operator.yaml \
    --namespace monitoring --version 6.11.0 --atomic

# kubectl delete -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/alertmanager.crd.yaml
# kubectl delete -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheus.crd.yaml
# kubectl delete -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheusrule.crd.yaml
# kubectl delete -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/servicemonitor.crd.yaml
# kubectl delete -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/podmonitor.crd.yaml

helm upgrade --install blue-green charts/blue-green --namespace blue-green -f values/blue-green-v1.yaml

helm upgrade --install blue-green charts/blue-green --namespace blue-green --set replicaCount=3 -f values/blue-green-v1.yaml

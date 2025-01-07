# Readme

This repository contains resources for hands-on exercises and demonstrations for various Kubernetes-related tools.

If you want some practical tasks to get your hands dirty with Kubernetes, head on to the [tasks](tasks) folder.

If you need a local Kubernetes cluster to play with, install [kind](https://github.com/kubernetes-sigs/kind) and then use the commands below to create a cluster that works with NetworkPolicies and PodSecurityStandards.

KIND setup with Cilium for NetworkPolicies and PodSecurityPolicies enforced:
```shell
kind create cluster --config kind/cni-config.yaml
# Configure PodSecurityStandards
kubectl label ns --all \
    pod-security.kubernetes.io/enforce=baseline
kubectl label --overwrite ns kube-system pod-security.kubernetes.io/enforce=privileged
# Set up Cilium
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.16.5 --namespace kube-system

```

The commands above creates a cluster with

- [Cilium](https://cilium.io/) as network plugin to enforce NetworkPolicies
- enforces the `permissive` Pod Security Standard for the kube-system namespace
- enforces the `baseline` Pod Security Standard for all other namespaces.

NOTE: Of you create new namespaces, you will need to label them also in order to enforce the PSS!

## Some handy snippets

KIND setup with ingress
```shell
kind create cluster --config kind/config.yaml
# Install ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
```

### Test applications

Blue-green:
```shell
kubectl create namespace blue-green
helm upgrade --install blue-green charts/blue-green --namespace blue-green -f values/blue-green-v1.yaml

helm upgrade --install blue-green charts/blue-green --namespace blue-green --set replicaCount=3 -f values/blue-green-v1.yaml
```

### Prometheus-operator

Deploy prometheus-operator
```shell
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/alertmanager.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheus.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheusrule.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/servicemonitor.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/podmonitor.crd.yaml

helm upgrade --install prom-operator stable/prometheus-operator \
    --set alertmanager.config.global.slack_api_url=$(pass Udda/slack-demo-hook) \
    -f values/prometheus-operator.yaml \
    --namespace monitoring --version 6.11.0 --atomic
```

### PromQL

Taken from https://blog.freshtracks.io/a-deep-dive-into-kubernetes-metrics-part-3-container-resource-metrics-361c5ee46e66

- **container_memory_cache:** Number of bytes of page cache memory.
- **container_memory_rss:** Size of RSS in bytes.
- **container_memory_swap:** Container swap usage in bytes.
- **container_memory_usage_bytes:** Current memory usage in bytes, including all memory regardless of when it was accessed.
- **container_memory_max_usage_bytes** Maximum memory usage recorded in bytes.
- **container_memory_working_set_bytes** Current working set in bytes.
- **container_memory_failcnt** Number of memory usage hits limits.
- **container_memory_failures_total** Cumulative count of memory allocation failures.

```
container_memory_usage_bytes{namespace="monitoring", container!="POD"}
(kube_pod_container_resource_requests{namespace="monitoring", container!="POD"}) / 1024 / 1024

sum(kube_pod_container_resource_requests{namespace="monitoring", container!="POD"}) by(pod)

sum(kube_pod_container_resource_requests{namespace="monitoring", container!="POD"}) by(container) - sum(container_memory_usage_bytes{namespace="monitoring", container!="POD"}) by(container)

sum(container_memory_usage_bytes{namespace="monitoring", container!="POD"}) by(container) / sum(kube_pod_container_resource_requests{namespace="monitoring", container!="POD"}) by(container)

# Ratio of running containers
count(kube_pod_status_phase{phase="Running"} == 1) / count(kube_pod_status_phase{phase="Running"})
# Sum containers into pods
sum(count(kube_pod_status_phase{phase="Running"} == 1)) by(pod) / sum(count(kube_pod_status_phase{phase="Running"})) by(pod)

# Blue-green
kube_deployment_status_replicas{deployment="blue-green"} / kube_deployment_spec_replicas{deployment="blue-green"}
```

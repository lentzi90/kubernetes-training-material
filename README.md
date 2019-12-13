# Readme

This repository contains resources for hands-on exercises and demonstrations for various Kubernetes-related tools.

If you want some practical tasks to get your hands dirty with Kubernetes, head on to the [tasks](tasks) folder.

If you need a local Kubernetes cluster to play with, install [kind](https://github.com/kubernetes-sigs/kind) and then use the commands below to create a cluster that works with NetworkPolicies and PodSecurityPolicies.

KIND setup with Cilium for NetworkPolicies and PodSecurityPolicies enforced:
```shell
kind create cluster --config kind/NP-PSP-config.yaml
# Add PSPs and RBAC
kubectl create -f manifests/PSP/
# Set up Cilium
kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.6/install/kubernetes/quick-install.yaml
```

The commands above creates a cluster with

- [Cilium](https://cilium.io/) as network plugin to enforce NetworkPolicies
- the PodSecurityPolicy admission plugin enabled to enforce PodSecurityPolicies
- two basic PodSecurityPolicies (`permissive` and `restrictive`) along with some RBAC that
  1. allow service accounts in `kube-system` to run privileged Pods using the `permissive` PSP
  2. allow all service accounts to use the `restrictive` PSP

## Some handy snippets

Minikube setup with Cilium for NetworkPolicies:
```shell
minikube start --network-plugin=cni
minikube ssh -- sudo mount bpffs -t bpf /sys/fs/bpf
kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.6/install/kubernetes/quick-install.yaml
```

### Kubespray on AWS

Terraform:
```shell
cd terraform/aws
terraform init
terraform apply
# Copy hosts.ini to kubespray inventory
```

Kubspray installation and upgrade:
```shell
git checkout release-2.10
pipenv install
pipenv shell
ansible -i inventory/aws/hosts.ini -m raw all -b -a "apt -yq install python"
# Install
ansible-playbook -i inventory/aws/hosts.ini -b cluster.yml
# Upgrade
git checkout release-2.11
# Change the version in group_vars/k8s-cluster/k8s-cluster.yml
ansible-playbook -i inventory/aws/hosts.ini -b upgrade-cluster.yml
```

Download `kubeconfig`:
```shell
ssh ubuntu@$IP_ADDRESS "mkdir .kube && sudo cp /etc/kubernetes/admin.conf .kube/config && sudo chown ubuntu:ubuntu .kube/config"
scp ubuntu@$IP_ADDRESS:~/.kube/config kubeconfig
# TODO: Replace server address with loadbalancer public DNS
export KUBECONFIG=$(pwd)/kubeconfig
```

### Helm and Tiller setup

Initialize helm with certificates:
```shell
./scripts/initialize-cluster.sh certs
source scripts/helm-env.sh certs/kube-system/certs
helm version
```

Initialize helm without certificates:
```shell
# Cluster wide tiller
kubectl -n kube-system create sa tiller
kubectl create clusterrolebinding tiller --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
# Insecure tiller, just for demo
helm init --service-account=tiller --history-max 200
# Wait for tiller to start
kubectl rollout status deployment tiller-deploy -n kube-system
```

### Test applications

Deploy test app:
```shell
kubectl create ns app-frontend
kubectl create ns app-backend
kubectl create ns app-database

helm upgrade --install k8s-front charts/test-app-frontend-chart \
  -f values/k8s-test-app-front.yaml
helm upgrade --install k8s-back charts/test-app-backend-chart \
  -f values/k8s-test-app-backend.yaml
helm upgrade --install k8s-database charts/test-app-database-chart \
  -f values/k8s-test-app-database.yaml
```

Blue-green:
```shell
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

### Kube-backup

Prereq: Set up a git repository and create a ssh-key (use `ssh-keygen`) with write access to it.
You also need to create a `known_hosts` file (e.g. `ssh-keyscan gitlab.com > known_hosts`).

Deploy kube-backup:
```shell
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
# Deploy kube-backup
kubectl apply -f manifests/backup
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

# Readme

This repository contains resources for hands-on exercises and demonstrations for various Kubernetes-related tools.

Minikube with Cilium for network policies: https://docs.cilium.io/en/v1.6/gettingstarted/minikube/

## Some handy snippets

Minikube setup with Cilium for NetworkPolicies:
```shell
minikube start --network-plugin=cni
minikube ssh -- sudo mount bpffs -t bpf /sys/fs/bpf
kubectl create -f https://raw.githubusercontent.com/cilium/cilium/v1.6/install/kubernetes/quick-install.yaml
```

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
```

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

PromQL:
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

Misc:
```
helm upgrade --install blue-green charts/blue-green --namespace blue-green -f values/blue-green-v1.yaml

helm upgrade --install blue-green charts/blue-green --namespace blue-green --set replicaCount=3 -f values/blue-green-v1.yaml
```

# Demonstration of RBAC, PSS and NetworkPolicies

KIND setup with Cilium for NetworkPolicies and PodSecurityPolicies enforced:
```shell
kind create cluster --config kind/cni-config.yaml
# Set up Cilium
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.16.5 --namespace kube-system

#
# Network policies
#

# Create demo namespaces red and blue
kubectl apply -f tasks/02-networkpolicies/blue-ns.yaml
kubectl apply -f tasks/02-networkpolicies/red-ns.yaml
# Create demo deployments and services
kubectl apply -f tasks/02-networkpolicies/blue-nginx-deploy.yaml
kubectl apply -f tasks/02-networkpolicies/red-nginx-deploy.yaml
kubectl apply -f tasks/02-networkpolicies/blue-nginx-svc.yaml
kubectl apply -f tasks/02-networkpolicies/red-nginx-svc.yaml

# Start two test pods
kubectl -n blue run busybox --rm -ti --image=busybox /bin/sh
kubectl -n red run busybox --rm -ti --image=busybox /bin/sh

# Check that each demo deployment can be reached
wget -q -O - nginx.blue.svc.cluster.local
wget -q -O - nginx.red.svc.cluster.local

# Label kube-system
kubectl label namespace kube-system system=true
# Apply a default deny policy in red and blue
kubectl apply -f tasks/02-networkpolicies/default-deny.yaml
# Allow blue DNS and egress from blue to red
kubectl apply -f tasks/02-networkpolicies/blue-egress.yaml
# Allow red DNS and ingress from blue to red
kubectl apply -f tasks/02-networkpolicies/red-ingress.yaml

#
# RBAC
#

# Create Roles and RoleBindings for users red and blue
kubectl apply -f tasks/01-rbac/blue-role.yaml
kubectl apply -f tasks/01-rbac/red-role.yaml
kubectl apply -f tasks/01-rbac/blue-rolebinding.yaml
kubectl apply -f tasks/01-rbac/red-rolebinding.yaml

# Check permissions:
kubectl auth can-i create deploy.apps -n red --as red # should be yes
kubectl auth can-i create deploy.apps -n red --as blue # should be no
kubectl auth can-i create deploy.apps -n blue --as blue # should be yes
kubectl auth can-i create deploy.apps -n blue --as red # should be no

#
# Pod security standards
#

# Check how existing workload would be affected by pod security:
kubectl label --dry-run=server --overwrite ns --all \
    pod-security.kubernetes.io/enforce=baseline

# Use labels to make the red namespace use privileged PSS
# and the blue use restricted
kubectl label --overwrite ns red \
    pod-security.kubernetes.io/enforce=privileged
kubectl label --overwrite ns blue \
    pod-security.kubernetes.io/enforce=restricted

# Demo deployments for testing
kubectl -n blue apply -f tasks/01-rbac/demo-root-deploy.yaml
kubectl -n red apply -f tasks/01-rbac/demo-root-deploy.yaml
kubectl -n blue apply -f tasks/01-rbac/demo-non-root-deploy.yaml
kubectl -n red apply -f tasks/01-rbac/demo-non-root-deploy.yaml
```

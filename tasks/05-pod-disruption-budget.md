# Pod disruption budget

Deploy a simple nginx application in a three node kind cluster to work with:
```shell
kind create cluster --config kind/config.yaml
export KUBECONFIG=$(kind get kubeconfig-path)
kubectl create ns ha
kubectl apply -f manifests/availability-resilience/nginx-deploy.yaml
```

1. Create a PodDisruptionBudget for the nginx app that allows a maximum of 1 unavailable pod.
  *Hint:* you can use `kubectl create`.
2. Verify that it is working:
  1. Drain the first worker: `kubectl drain kind-worker --ignore-daemonsets --delete-local-data`
  2. Check that both nginx pods run on the other worker: `kubectl get pods -o wide -n ha`
  3. Uncordon the first worker: `kubectl uncordon kind-worker`
  4. Drain the second worker: `kubectl drain kind-worker2 --ignore-daemonsets --delete-local-data`
  5. Observe the error when evicting the second pod because of the PDB.
  6. Uncordon the second worker: `kubectl uncordon kind-worker2`

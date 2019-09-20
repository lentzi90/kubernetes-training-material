# Pod anti-affinity

Deploy a simple nginx application in a three node kind cluster to work with:
```shell
kind create cluster --config kind/config.yaml
export KUBECONFIG=$(kind get kubeconfig-path)
kubectl create ns ha
kubectl apply -f manifests/availability-resilience/nginx-deploy.yaml
```

1. Update the Deployment to include a required pod anti-affinity between pods on the same node.
2. Verify that it is working:
  1. Drain the first worker: `kubectl drain kind-worker --ignore-daemonsets --delete-local-data`
  2. Check that one nginx pod is now pending (since it cannot be scheduled on the same node as the other): `kubectl get pods -o wide -n ha`
  3. Uncordon the first worker: `kubectl uncordon kind-worker`
  4. Check that both pods are now scheduled again: `kubectl get pods -o wide -n ha`
3. Try rolling out a new version by setting the image to `lennartj/blue-green:v1`.
  Note that the new pod is stuck pending because of the anti-affinity and lack of extra nodes.
4. Change the rolling update strategy so that `maxSurge` is set to 0.
  This will allow the rollout to proceed since we keep the number of pods lower than the number of nodes.

# Upgrade and roll back helm charts

Practice upgrading and rolling back a helm release.

Prereq: Create a Kubernetes cluster using minikube or kind, initialize helm and install the blue-green app:

```shell
minikube start
# Cluster wide tiller
kubectl -n kube-system create sa tiller
kubectl create clusterrolebinding tiller --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
# Insecure tiller, just for demo
helm init --service-account=tiller --history-max 200
# Wait for tiller to start
kubectl rollout status deployment tiller-deploy -n kube-system
# Install blue-green app
helm upgrade --install blue-green charts/blue-green --namespace blue-green -f values/blue-green-v1.yaml
```

Start by checking that the application is running and that you can access it.

1. Find the node port of the `blue-green` Service in the `blue-green` namespace for example by listing the services using `kubectl get svc`.
2. Find the IP address of one of the nodes for example by listing the nodes in wide mode: `kubectl get nodes -o wide`.
   Note: If this IP doesn't work, try the IP returned by `minikube ip` instead.
3. Try accessing http://$NODE_IP:$NODE_PORT in your browser.
   You should see a **blue** page.
4. Upgrade the release by using `values/blue-green-v2.yaml`
5. Check that you can see the **green** version of the blue-green app
6. Try upgrading to an invalid version, using `values/blue-green-invalid.yaml`.
   What happened? What state is the release in now? (Check `helm list` and `helm history blue-green`.)
7. Check the history (`helm history blue-green`) and rollback to the previous version (see `helm rollback --help`).
8. Try upgrading again to the invalid release, but this time using the `--atomic` flag.
   Note: To speed this up a bit, set the flag `--timeout 10`
   What happened this time? Check `helm history`!

---

Snippet for finding the URL of the blue-green app:
```shell
export NODE_PORT=$(kubectl get --namespace blue-green -o jsonpath="{.spec.ports[0].nodePort}" services blue-green)
export NODE_IP=$(kubectl get nodes --namespace blue-green -o jsonpath="{.items[0].status.addresses[0].address}")
echo http://$NODE_IP:$NODE_PORT
```
Alternative snippet when using minikube:
```shell
export NODE_PORT=$(kubectl get --namespace blue-green -o jsonpath="{.spec.ports[0].nodePort}" services blue-green)
export NODE_IP=$(minikube ip)
echo http://$NODE_IP:$NODE_PORT
```

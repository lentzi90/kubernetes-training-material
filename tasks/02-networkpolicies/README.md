# Network policies

Prereq: a Kubernetes cluster with support for NetworkPolicies.
If you did 01-rbac, you should already have this, otherwise, check the [README.md](../../README.md) for how to set up minikube with Cilium.

1. Create default deny NetworkPolicies (both incoming and outgoing) for the `red` and `blue` namespaces.
2. Create NetworkPolicies that allow Pods in `blue` to send packets to `red` and Pods in `red` to receive packets from `blue`.
   For name resolution to work, you will also need to allow traffic from `red` and `blue` to `kube-system` where the nameserver is.

   *Hint:* You will need to label the namespaces.
   - Optional: Limit access to `kube-system` only to CoreDNS.
3. Create an nginx deployment and service in both namespaces: `kubectl -n [red|blue] create deploy nginx --image nginx`, `kubectl -n [red|blue] expose deploy nginx --port 80`
4. Check that you **can** reach the nginx Service in `red` from `blue`:
   ```shell
   kubectl -n blue run busybox --generator=run-pod/v1 --rm -ti --image=busybox /bin/sh
   wget -q -O - nginx.red
   ```
5. Check that you **cannot** reach the nginx Service in `blue` from `red`:

   ```shell
   kubectl -n red run busybox --generator=run-pod/v1 --rm -ti --image=busybox /bin/sh
   wget -q -O - nginx.blue
   ```
6. Check other namespaces and combinations as you like. Can you reach the service from its own namespace? How about from `kube-system` or `default`?

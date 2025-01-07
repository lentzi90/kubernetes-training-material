# RBAC

Prereq: a Kubernetes cluster with support for RBAC and optionally NetworkPolicies (for next task).
Check the [README.md](../../README.md) for how to set up KIND with Cilium.

1. Create two namespaces named `blue` and `red`.
2. Create Roles and RoleBindings that allow users `blue` and `red` to `create`, `patch`, `update` and `delete` Deployments and Services in their respective namespaces.
   Note that Deployments belong to the `apps` API group and Services to the "core" (`""`).

   *Hint:* Use `kubectl create` instead of searching for examples on the internet.
   Check `kubectl create --help`, use `-o yaml` and `--dry-run` to see the manifest without making changes to the cluster.
3. Check that your Roles and RoleBindings work by using `kubectl auth can-i`.
   Here are some examples:

   ```shell
   kubectl auth can-i create deploy.apps -n red --as red # should be yes
   kubectl auth can-i create deploy.apps -n red --as blue # should be no
   kubectl auth can-i create deploy.apps -n blue --as blue # should be yes
   kubectl auth can-i create deploy.apps -n blue --as red # should be no
   # List all permissions for red in red
   kubectl auth can-i --list -n red --as red
   # Resources          Non-Resource URLs   Resource Names   Verbs
   # services           []                  []               [create patch update delete]
   # deployments.apps   []                  []               [create patch update delete]
   # ...
   ```
4. Label the `red` namespace to enforce the `privileged` PodSecurityStandard and the `blue` namespace to enforce the `restrictive` PodSecurityStandard.
   The labels look like this:
   `pod-security.kubernetes.io/enforce=privileged` (privileged)
   `pod-security.kubernetes.io/enforce=restricted` (restricted).
5. Try the demo deployments `demo-non-root-deploy.yaml` and `demo-root-deploy.yaml` and see how they behave.
   You can also try explicitly specifying the `securityContext` for these Deployments (see the manifests).
   How does the behavior differ?
   You can also deploy everything first and label the namespaces afterwards!
   A useful check then is to do a dry-run to see if there are any issues:

   ```bash
   kubectl label --dry-run=server --overwrite ns blue \
       pod-security.kubernetes.io/enforce=restricted
   ```

# RBAC

1. Set up a cluster with kind: `kind cluster create`
2. Configure access to the cluster: `export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"`
3. Create two namespaces named `blue` and `red`.
4. Create Roles and RoleBindings that allow users `blue` and `red` to `create`, `patch`, `update` and `delete` Deployments and Services in their respective namespaces.
  Note that Deployments belong to the `apps` API group and Services to the "core" (`""`).

  *Hint:* Use `kubectl create` instead of searching for examples on the internet.
  Check `kubectl create --help`, use `-o yaml` and `--dry-run` to see the manifest without making changes to the cluster.
5. Check that your Roles and RoleBindings work by using `kubectl auth can-i`.
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
6. Create a Role and RoleBinding that allow the `default` ServiceAccount in the `red` namespace to use the `privileged` PodSecurityPolicy.
7. Check that your Role and RoleBinding are working with `kubectl auth can-i`.
  Note that you can impersonate ServiceAccounts using this syntax: `kubectl -n namespace auth can-i verb resource --as system:serviceaccount:namespace:name`.

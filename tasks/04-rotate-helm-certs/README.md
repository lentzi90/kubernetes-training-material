# Rotate certificates for helm and tiller

Prereq:
```shell
./scripts/initialize-cluster.sh certs
source scripts/helm-env.sh certs/kube-system/certs
helm version
```

If the certificates get compromised or simply expire, you will need to generate new ones and replace the old certificates.
To do this without affecting the workload, you need to do three things:

1. Generate new certificates
2. Update the `tiller-secret` with the new certificates
3. Delete the old tiller pods

More detailed instructions below.

Use the script [generate-certs.sh](../../scripts/generate-certs.sh) to generate the new certificates.
Note that it will not overwrite the old certificates, so you will need to remove the old ones or use a new folder.

Example:
```shell
./scripts/generate-certs.sh new-certs
```

Helm does not yet [support certificate rotation](https://github.com/helm/helm/issues/5216), so we need to do it manually.
This means replacing the `tiller-secret`s in the cluster and restarting the tiller pods.

Create new secrets for all tiller deployments in the following way:
```shell
export NAMESPACE=kube-system
# Create the secret and replace the old
kubectl -n ${NAMESPACE} create secret generic tiller-secret \
  --from-file=ca.crt=new-certs/ca.pem \
  --from-file=tls.crt=new-certs/tiller.pem \
  --from-file=tls.key=new-certs/tiller-key.pem \
  --dry-run -o yaml | kubectl apply -f -
# Label so that tiller will recognize it
kubectl -n ${NAMESPACE} label secret tiller-secret app=helm name=tiller
# Delete the old tiller pod, the new one will pick up the new certificates.
kubectl -n ${NAMESPACE} rollout restart deployment tiller-deploy
```

Make sure you can access tiller using the new certificates:

```shell
source scripts/helm-env.sh new-certs
helm version
```
 It is also a good idea to check that you cannot use the old certificates anymore.

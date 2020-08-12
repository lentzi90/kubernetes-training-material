# Cert-manager basics

Deploy a simple nginx application in a three node kind cluster to work with:
```shell
kind create cluster --config kind/config.yaml

# Install ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml

# Install cert-manager
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.16.1/cert-manager.yaml
# Create a namespace to experiment in
NAMESPACE=demo
kubectl create namespace ${NAMESPACE}
```

1. Create a self signed Issuer
2. Create a Certificate for `example.com` using the Issuer from the previous step.
3. Check the generated Secret and inspect the Certificate.
4. How long is the certificate valid?

   *Hint:* This snippet with custom columns can come in handy if you want to check the remaining duration of all certificates in a cluster:

   ```shell
   kubectl get certificate --all-namespaces --sort-by status.notAfter \
     --output=custom-columns=NAMESPACE:metadata.namespace,NAME:metadata.name,NOT_AFTER:status.notAfter,RENEWAL_TIME:status.renewalTime,MESSAGE:status.conditions[0].message
   ```
5. Create an nginx Deployment with Service and Ingress that makes use of the Certificate
6. Check that it is working by curling the deployment.
   *Hint:* The ingress controller can be accessed at 127.0.0.1.
   Use the `--resolve` flag of curl to work around DNS.
   ```shell
   # This should get the "Welcome to nginx!" page
   curl --resolve example.com:443:127.0.0.1 -k https://example.com
   # Check some certificate details
   curl --resolve example.com:443:127.0.0.1 -ksvI https://example.com 2>&1 | grep -A 5 "Server certificate"
   # Get the full certificate with openssl
   openssl s_client -showcerts -servername example.com -connect 127.0.0.1:443 </dev/null
   # Get all details
   echo | openssl s_client -servername example.com -connect 127.0.0.1:443 2>/dev/null | openssl x509 -text
   # Compare with the Secret in kubernetes (should be identical)
   kubectl -n demo get secret demo-certs -o jsonpath="{.data.tls\.crt}" | base64 -d | openssl x509 -text
   ```

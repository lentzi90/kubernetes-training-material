# Resource requests

Prereq: Start minikube and enable the metrics-server addon: `minikube addons enable metrics-server`

1. Create a namespace for the demo: `kubectl create ns resource-demo`
2. Deploy the demo Deployment: `kubectl apply -f manifests/resource-requests/demo-deploy.yaml`
3. Observe that the Pod is OOMKilled since it has too low memory limit.
4. Change the Deployment memory request and limit to `1000Gi` and apply.
5. Observe that the new Pod stays pending since no node has sufficient memory.

# cluster creation (managed nodes + oidc)

```
cd eks-cluster
terraform init
terraform apply --var-file=vars.json --auto-approve
```

```
kubectl get nodes -o wide
kubectl get pods -A -o wide
```

# aws load balancer controller installation

```
cd eks-lb
terraform init
terraform apply --var-file=vars.json --auto-approve
```

```
kubectl get deployment -n kube-system aws-load-balancer-controller
```

# eks karpenter
```
cd eks-karpenter
terraform init
terraform apply --var-file=vars.json --auto-approve
```

```
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter -c controller
``` 

# spring cloud microservices deployment

```
cd eks-apps
terraform init
terraform apply --var-file=vars.json --auto-approve
```

```
kubectl get svc -n piggymetrics
kubectl get pod -n piggymetrics
kubectl get deployment -n piggymetrics
kubectl get sts -n piggymetrics
```

# spring cloud microservices hpa

```
cd eks-hpa
terraform init
terraform apply --var-file=vars.json --auto-approve
```

```
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/pods"
kubectl top pod -n piggymetrics
kubectl get hpa -n piggymetrics -w

```

```
kubectl run -i --tty load-generator --image=busybox /bin/sh
export gateway_clusterip=x.x.x.x
while true; do wget -q -O - http://${gateway_clusterip}/accounts/demo; done
kubectl delete pod load-generator
```

# spring cloud config image ci (github+codebuild+ecr)
```
cd eks-cli
terraform init
terraform apply --var-file=vars.json --auto-approve
```

# aws distro opentelemetry (export to x-ray and prometheus)
```
cd eks-adot-operator
terraform init
terraform apply --var-file=vars.json --auto-approve
```
```
cd eks-adot-collector
terraform init
terraform apply --var-file=vars.json --auto-approve
```
```
kubectl get all -n observability
kubectl get all -n opentelemetry-operator-system
```

## note
piggymetrics project link https://github.com/sqshq/piggymetrics

update config child project - replacing eureka server with env variable

# cluster creation

```
cd eks-cluster
terraform init
terraform apply --vars-file=vars.json --auto-approve
```

```
kubectl get nodes -o wide
kubectl get pods -A -o wide
```

# aws load balancer controller installation

```
cd eks-lb
terraform init
terraform apply --vars-file=vars.json --auto-approve
```

```
kubectl get deployment -n kube-system aws-load-balancer-controller
```

# spring cloud microservices deployment

```
cd eks-apps
terraform init
terraform apply --vars-file=vars.json --auto-approve
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
terraform apply --vars-file=vars.json --auto-approve
```

```
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/pods"
kubectl get hpa -n piggymetrics
kubectl top pod -n piggymetrics
```

# spring cloud config image ci
```
cd eks-cli
terraform init
terraform apply --vars-file=vars.json --auto-approve
```

## note
piggymetrics project link https://github.com/sqshq/piggymetrics

update config child project - replacing eureka server with env variable

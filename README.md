Azure NPM for Windows
=====================

Create cluster with Azure NPM plugin installed for both Linux and Windows nodes
-------------------------------------------------------------------------------

```sh
# Adjust the environment variables in script to your needs.
./manual-npm-install-on-aks-ws22.sh
```

Create namespaces and deploy apps
---------------------------------

```sh
# Namespace "A" - test clients
kubectl create ns nsa
kubectl label ns nsa ingress-allow="yes"
# Namespace "B" - destination apps
kubectl create ns nsb

# Deploy the test clients (one one a Linux node and another on a Windows node)
kubectl apply -f agnhost-windows.yaml -n nsa
kubectl apply -f agnhost-linux.yaml -n nsa

# Destination apps (Linux and Windows)
kubectl apply -f win-sample-app.yaml -n nsb
kubectl apply -f linux-sample-app.yaml -n nsb
```

Test connectivity without network policies
------------------------------------------

```sh
kubectl get pod -n nsb -o wide

srcNamespace="${1:?Missing source namespace}"
srcPod="${2:?Missing source pod}"
destIP="${3?:Missing destination IP}"

function PodlabelToIp() {
    local labelSelector=$1
    local retVal=$(kubectl get pod -n nsb -l $labelSelector -o jsonpath="{.items[*].status.podIP}")
    echo $retVal
}

# Linux to Linux (YES)
./connect-agnhosts.sh nsa test-agnhost-linux $(PodlabelToIp "app=linuxapp")

# Linux to Windows (YES)
./connect-agnhosts.sh nsa test-agnhost-linux $(PodlabelToIp "app=linuxapp")

# Windows to Linux (YES)
./connect-agnhosts.sh nsa test-agnhost-windows $(PodlabelToIp "app=winapp")

# Windows to Windows (YES)
./connect-agnhosts.sh nsa test-agnhost-windows $(PodlabelToIp "app=winapp")
```

Test connectivity with network policies
---------------------------------------

Ingress policy:

```sh
# Only allow ingress to Windows pod from app == win-client
kubectl apply -f ./windows-ingress-policy.yaml -n nsb

# Linux to Linux (YES)
./connect-agnhosts.sh nsa test-agnhost-linux $(PodlabelToIp "app=linuxapp")

# Linux to Windows (YES)
./connect-agnhosts.sh nsa test-agnhost-linux $(PodlabelToIp "app=linuxapp")

# Windows to Linux (YES, app == win-client)
./connect-agnhosts.sh nsa test-agnhost-windows $(PodlabelToIp "app=winapp")

# Windows to Windows (NO, app != win-client)
./connect-agnhosts.sh nsa test-agnhost-windows $(PodlabelToIp "app=winapp")

# Cleanup
kubectl delete -f windows-ingress-policy.yaml -n nsb
```

Egress policy:

```sh
# Only allow egress from Windows pod for app != win-client
kubectl apply -f windows-egress-policy.yaml -n nsa

# Windows to Linux (YES, app != win-client)
./connect-agnhosts.sh nsa test-agnhost-windows $(PodlabelToIp "app=winapp")

# Windows to Windows (NO, app == win-client)
./connect-agnhosts.sh nsa test-agnhost-windows $(PodlabelToIp "app=winapp")

# Cleanup
kubectl delete -f windows-egress-policy.yaml -n nsa
```

Cleanup
-------

```sh
kubectl delete -f agnhost-windows.yaml -n nsa
kubectl delete -f agnhost-linux.yaml -n nsa

kubectl delete -f win-sample-app.yaml -n nsb
kubectl delete -f linux-sample-app.yaml -n nsb

kubectl delete ns nsa
kubectl delete ns nsb
```

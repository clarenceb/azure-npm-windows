#!/bin/bash

srcNamespace="${1:?Missing source namespace}"
srcPod="${2:?Missing source pod}"
destIP="${3?:Missing destination IP}"

echo "Trying to connect from $srcNamespace/$srcPod to $destIP on TCP port 80"

set -x
kubectl exec -n $srcNamespace $srcPod -c agnhost -- /agnhost connect $destIP:80 --timeout=3s --protocol=tcp
exitcode=$?
set +x

if [[ $exitcode == 0 ]]; then
    echo "Successfully connected from $srcNamespace/$srcPod to $destIP on TCP port 80"
    exit 0
else
    echo "Failed to connect! (from $srcNamespace/$srcPod to $destIP on TCP port 80)"
    exit 1
fi

#!/bin/bash
cd /home/akash
. variables
if [ -f ./microk8s-bootstrap.sh ]; then
  rm ./microk8s-bootstrap.sh
fi
if [ ! -f variables ]; then
wget -q https://raw.githubusercontent.com/88plug/akash-provider-tools/main/microk8s-bootstrap.sh
chmod +x microk8s-bootstrap.sh ; echo "Enter your password to start the Akash installer" ; sudo ./microk8s-bootstrap.sh
else
export KUBECONFIG=/home/akash/.kube/kubeconfig
echo "Variables file deteted - Setup complete"
fi

#!/bin/bash
cd /home/akash
if [ -f ./microk8s-bootstrap.sh ]; then
  rm ./microk8s-bootstrap.sh
fi
if [ ! -f variables ]; then
clear

while true
do
clear
read -p "Which install should we use (k3s/microk8s/kubespray)? (microk8s) : " METHOD_
read -p "Are you sure you want to install with the $METHOD_ method? (y/n) " choice
case "$choice" in
  y|Y ) break;;
  n|N ) echo "Please try again with microk8s if unsure";;
  * ) echo "Invalid entry, please try again with Y or N" ; sleep 3;;
esac
done

if [[ $METHOD_ == "kubespray" ]]; then
wget -q https://raw.githubusercontent.com/88plug/akash-provider-tools/main/kubespray-bootstrap.sh
chmod +x kubespray-bootstrap.sh ; echo "No setup detected! Enter the default password 'akash' to start the Akash installer" ; sudo ./kubespray-bootstrap.sh
fi
if [[ $METHOD_ == "microk8s" ]]; then
wget -q https://raw.githubusercontent.com/88plug/akash-provider-tools/main/microk8s-bootstrap.sh
chmod +x microk8s-bootstrap.sh ; echo "No setup detected! Enter the default password 'akash' to start the Akash installer" ; sudo ./microk8s-bootstrap.sh
fi
if [[ $METHOD_ == "k3s" ]]; then
wget -q https://raw.githubusercontent.com/88plug/akash-provider-tools/main/k3s-bootstrap.sh
chmod +x microk8s-bootstrap.sh ; echo "No setup detected! Enter the default password 'akash' to start the Akash installer" ; sudo ./k3s-bootstrap.sh
fi


else
. variables
export KUBECONFIG=/home/akash/.kube/kubeconfig
echo "Variables file deteted - Setup complete"
fi

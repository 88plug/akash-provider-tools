#!/bin/bash
cd /home/akash
if [ -f ./*bootstrap.sh ] ; then
  echo "Found an old bootstrap - cleaning up"
  rm ./microk8s-bootstrap.sh ; rm ./k3s-bootstrap.sh ; rm ./kubespray-bootstrap.sh
fi

if [ ! -f variables ]; then
clear

while true
  do
    clear
    read -p "Which Kubernetes install method would you like to use (k3s/microk8s/kubespray)? (microk8s) : " METHOD_
    read -p "Are you sure you want to install with the $METHOD_ method? (y/n) " choice
    case "$choice" in
      y|Y ) break;;
      n|N ) echo "Please try again with microk8s if unsure" ; sleep 3;;
      * ) echo "Invalid entry, please try again with Y or N" ; sleep 3;;
  esac
done

if [[ $METHOD_ == "kubespray" ]]; then
  wget -q --no-cache https://raw.githubusercontent.com/88plug/akash-provider-tools/main/kubespray-bootstrap.sh ; chmod +x kubespray-bootstrap.sh
  echo "No setup detected! Enter the default password 'akash' to start the Akash installer" ; sudo ./kubespray-bootstrap.sh
fi
if [[ $METHOD_ == "microk8s" ]]; then
  wget -q --no-cache https://raw.githubusercontent.com/88plug/akash-provider-tools/main/microk8s-bootstrap.sh ; chmod +x microk8s-bootstrap.sh ; 
  echo "No setup detected! Enter the default password 'akash' to start the Akash installer" ; sudo ./microk8s-bootstrap.sh
fi
if [[ $METHOD_ == "k3s" ]]; then
  wget -q --no-cache https://raw.githubusercontent.com/88plug/akash-provider-tools/main/k3s-bootstrap.sh ; chmod +x k3s-bootstrap.sh 
  echo "No setup detected! Enter the default password 'akash' to start the Akash installer" ; sudo ./k3s-bootstrap.sh
fi

else
. variables

if [[ $SETUP_COMPLETE == true ]]; then
export KUBECONFIG=/home/akash/.kube/kubeconfig
echo "Variables file deteted - Setup complete"
fi

fi

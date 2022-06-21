#!/bin/bash
#To be run on a single microk8s node - to get the base Akash provider software installed.  

#Depends / Microk8s / Kubectl / Helm
function depends(){
apt-get update && apt-get dist-upgrade -yqq ; apt-get install -y snapd sudo unzip
snap install microk8s --classic ; snap install kubectl --classic ; snap install helm --classic
microk8s enable dns:1.1.1.1
export KUBECONFIG=/var/snap/microk8s/current/credentials/client.config
kubectl get pods -A
}
depends

function akash(){
curl https://raw.githubusercontent.com/ovrclk/akash/master/godownloader.sh | sh -s -- "v0.16.4" ; cp bin/akash /usr/local/bin ; rm -rf akash ; akash version

akash keys add default --recover
#(paste mnemonic phrase and give wallet a password)
akash keys export default
#(enter new wallet password)
#(save output to key.pem)
}
akash

function create_config(){
read -p "Enter domain name to use (example.com): " DOMAIN_
read -p "Enter Akash wallet address : " ACCOUNT_ADDRESS_
read -p "Enter the Keyring password for the Akash wallet : " KEY_SECRET_
read -p "Enter the region for this server (us-west/eu-east) " REGION_
read -p "Enter the cpu type for this server (amd/intel) " CPU_
read -p "Enter the download speed of the connection in Mbps (1000) " DOWNLOAD_
read -p "Enter the upload speed of the connection in Mbps (250) " UPLOAD_

echo "DOMAIN=$DOMAIN_" > variables
echo "ACCOUNT_ADDRESS=$ACCOUNT_ADDRESS_" >> variables
echo "KEY_SECRET=$KEY_SECRET_" >> variables
echo "REGION=$REGION_" >> variables
echo "CPU=$CPU_" >> variables
echo "UPLOAD=$UPLOAD_" >> variables
echo "DOWNLOAD=$DOWNLOAD_" >> variables

echo "Get latest config from github"
wget https://raw.githubusercontent.com/88plug/akash-provider-tools/main/run-helm-microk8s.sh
wget https://raw.githubusercontent.com/88plug/akash-provider-tools/main/bid-engine-script.sh
chmod +x run-helm-microk8s.sh ; chmod +x bid-engine-script.sh
}
create_config

function start_akash(){
./run-helm-microk8s.sh
}
start_akash

#Add/scale the cluster with 'microk8s add-node' and use the token on additional nodes.

#!/bin/bash
#To be run on a single microk8s node - to get the base Akash provider software installed.  

#Depends / Microk8s / Kubectl / Helm
function depends(){
apt-get update && apt-get dist-upgrade -yqq ; apt-get install -y snapd sudo unzip
snap install microk8s --classic ; snap install kubectl --classic ; snap install helm --classic
export KUBECONFIG=/var/snap/microk8s/current/credentials/client.config
kubectl get pods -A
}
depends

#Fix Dns
cat <<EOF > /etc/systemd/resolved.conf
[Resolve]
DNS=1.1.1.1 1.0.0.1
FallbackDNS=8.8.8.10 8.8.8.8
#Domains=
#LLMNR=no
#MulticastDNS=no
DNSSEC=yes
DNSOverTLS=yes
#Cache=yes
#DNSStubListener=yes
#ReadEtcHosts=yes
EOF
systemctl restart systemd-resolved.service
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

#Install Akash and setup wallet
curl -sSfL https://raw.githubusercontent.com/ovrclk/akash/master/godownloader.sh | sh
cp bin/akash /usr/local/bin
rm -rf bin/
akash version

read -p "Enter mnemonic phrase to import your provider wallet (KING SKI GOAT...): " mnemonic_
read -p "Enter the new keyring password to protect the wallet with (NewWalletPassword): " KEY_SECRET_

echo "$mnemonic_" | akash keys add default --recover
unset mnemonic_
echo "$KEY_SECRET_ $KEY_SECRET_" | akash keys export default > key.pem

ACCOUNT_ADDRESS_=$(echo $KEY_SECRET_ | akash keys list | grep address | cut -d ':' -f2 | cut -c 2-)
BALANCE=$(akash query bank balances --node http://rpc.bigtractorplotting.com:26657 $ACCOUNT_ADDRESS_)
MIN_BALANCE=50

#if (( $(echo "$BALANCE < "50" | bc -l) )); then
#  echo "Balance is less than 50 AKT - you should send more coin to continue."
#  echo "Found a balance of $BALANCE on the wallet $ACCOUNT_ADDRESS_"
#else
#  echo "Found a balance of $BALANCE on the wallet $ACCOUNT_ADDRESS_"
#fi

read -p "Enter domain name to use (example.com) : " DOMAIN_
read -p "Enter the Keyring password for the Akash wallet : " KEY_SECRET_
read -p "Enter the region for this server (us-west/eu-east) : " REGION_
read -p "Enter the cpu type for this server (amd/intel) : " CPU_
read -p "Enter the download speed of the connection in Mbps (1000) : " DOWNLOAD_
read -p "Enter the upload speed of the connection in Mbps (250) : " UPLOAD_

echo "DOMAIN=$DOMAIN_" > variables
echo "ACCOUNT_ADDRESS=$ACCOUNT_ADDRESS_" >> variables
echo "KEY_SECRET=$KEY_SECRET_" >> variables
echo "REGION=$REGION_" >> variables
echo "CPU=$CPU_" >> variables
echo "UPLOAD=$UPLOAD_" >> variables
echo "DOWNLOAD=$DOWNLOAD_" >> variables

echo "Get latest config from github"
wget -q https://raw.githubusercontent.com/88plug/akash-provider-tools/main/run-helm-microk8s.sh
wget -q https://raw.githubusercontent.com/88plug/akash-provider-tools/main/bid-engine-script.sh
chmod +x run-helm-microk8s.sh ; chmod +x bid-engine-script.sh

./run-helm-microk8s.sh

#Add/scale the cluster with 'microk8s add-node' and use the token on additional nodes.
#Use 'microk8s enable dns:1.1.1.1' after you add more than 1 node.

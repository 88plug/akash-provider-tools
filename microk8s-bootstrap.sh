#!/bin/bash
#To be run on a single microk8s node - to get the base Akash provider software installed.
clear
cat <<EOF
MMMMMMMMMMMMMMMMMN0000000000000000XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX0OOOOOO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXOOOOOOOXMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWXdc:::::::::::::cdKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMk,.....',dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'.....'xWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMWKo;;;;;;;;;;;;;;;l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx........oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.......dWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWXd:;;;;;;;;;;;;;;l0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx........oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.......dWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMXx:;;;;;;;;;;;;;;cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx........oWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.......dWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMNk:;;;;;;;,;;;;;;ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXXXXNWMMMMMMMMMMMMMMWx........oWMMMMMMMMMMMMMMMMMMMMMMMWWNXXXNNWMMMMMMMMMMMMMMMMMMMMMMWNXXXXXXNWMMMMMMMMMWd.......dWWNXXXXNWMMMMM
MMMMMMMMMMMMMMMMMMMMMMNOc;;;;;;;;;;;;;;:xXMMMMMMMMMMMMMMMMMMMMMMMN0xl:;,''',:ldOkoooooodKMMMx........oWMMWKxooooooodKWMMMMWXOoc;,''',;:oxOxooooookNMMMMMMN0xl:;''''',;:lx0NMMMMMWd.......:oc,''',;lxXWMM
MMMMMMMMMWWWWWWWWWWWWWWNOc;;;;;;;;;;;;;;:dXWMMMMMMMMMMMMMMMMMMWKd;......................xMMMx........oWMWO;.......'dNMMMNOl,.....................;KMMMMNk:................:xNMMMWd..................,dXM
MMMMMMMNOdddddddddddddddxxl;;;;;;;;;;;;;,;oKWMMMMMMMMMMMMMMMMXd,........................xMMMx........oNNd'.......;kWMMW0c................. ......;KMMMXl....................cKMMWd..........'.........cK
MMMMMMNk:;;;;;;;;;;;;;;:kXKo;;;;;;;;;;;;;;;oKWMMMMMMMMMMMMMMKc........;oxkkkdc'.........xMMMx........o0c........cKWMMWk,.......'cdkkkxo;.........;KMMWd.......;dOOOko,.......oNMWd.......'o0XKk;.......d
MMMMMXx:;;;;;;;;;;;;;;cONMWXd:;;;;;;;;;;;;;;l0WMMMMMMMMMMMMXl.......:ONMMMMMMWKo'.......xMMMx........,,.......'dNMMMMO,.......oKWMMMMMMNO:.......;KMMNl.......c0XNWMWKdddddddONMWd.......oNMMMMk'......c
MMMWXd:;;;;;;;;;;;;;;l0WMMMWXx:;;;;;;;;;;;;;;cOWMMMMMMMMMMMk'......:KMMMMMMMMMMWx.......xMMMx................,OWMMMMNl.......dNMMMMMMMMMMXc......;KMMWO,........';:codk0XWMMMMMMWd.......dWMMMMO'......c
MMWKo;;;;;;;;;;;;;;;l0WMMMMMMNk:;;;;;;;;;;;;;;ckNMMMMMMMMMWo.......dWMMMMMMMMMMMK;......xMMMx...............;0WMMMMMK;......;0MMMMMMMMMMMWx......;KMMMWOc...............':dKWMMMWd.......dWMMMMO'......c
MW0l;;;;;;;;;;;;;;;oKWMMMMMMMMNOc;;;;;;;;;;;;;;:xXWMMMMMMMWd.......oNMMMMMMMMMMM0,......xMMMx...............'dNMMMMMK;......,OMMMMMMMMMMMWo......;KMMMMMN0d:,..............'oXMMWd.......dWMMMMO'......c
W0l;;;;;;;;;;;;;;:dXWMMMMMMMMMMWOl;;;;;;;;;;;;;;:dXWMMMMMMMO'......'xNMMMMMMMMWKc.......xMMMx.................lKMMMMNl.......:0WMMMMMMMMNx'......;KMMWWWWWNXK0kdol:,'........oNMWd.......dWMMMMO'......c
0l;;;;;;;;;;;;;;:oxkOOOOOOOOOOOOko;;;;;;;;;;;;;;;;xNMMMMMMMNo........:xKNWWWXOo,........xMMMx........cl'.......;OWMMM0;.......'oOXNWWNKkc........;KMMOc;;;;;;dNMMMWNKo.......:KMWd.......dWMMMMO'......c
Xx:;;;;;;;;;;;;ck0o,''''''''''''''',;,;;;;;;;;;;;l0WMMMMMMMMXo..........,::;'...........xWMWx........oXk,.......'xNMMW0:.........';::,'..........;KMM0;.......;odxxdo;.......lNMWd.......dWMMMMO'......c
MNk:;;;;;;;;;;cONWXd,''''''''''''''',;;;;;;;;;;;l0WMMMMMMMMMMNk:........................xMMWx........oWW0c........lKMMMXo'.......................;KMMW0:....................cKMMWd.......dWMMMMO'......c
MMNOc;;;;;;;;l0WMMMNx;''''''''''''''',,;;;;;,;;oKWMMMMMMMMMMMMMNOl,............'........xMMMx........oWMMXo........:0WMMWKd:'............'.......;KMMMMNkc'..............'ckNMMMWd.......dWMMMMO'......c
MMMW0l;;;;;;l0WMMMMMNk:''''''''''''''',,;;;;;:dXWMMMMMMMMMMMMMMMMWXOxoc::;:cldOK0xxxxxxkXMMMXkxxxxxkkKWMMMN0xxxxxxxx0WMMMMMWKkdlc:;::lox0KOxxxxxxONMMMMMMWXOdlc:;;;;:cldOXWMMMMMMKkxxxxxkKMMMMMXkxxxxxx0
MMMMW0l;;;;oKWMMMMMMMWO:''''''''''''''',,;,;:xNMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMWKo;:dXWMMMMMMMMMW0c''''''''''''''',,;ckNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMWXxkXMMMMMMMMMMMMWKo;;;;;;;;;;;;;;;;lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMWWMMMMMMMMMMMMMMWX0000000000000000KWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
EOF

read -p "Enter domain name to use for your provider (example.com) : " DOMAIN_
read -p "Enter mnemonic phrase to import your provider wallet (KING SKI GOAT...): " mnemonic_
#read -p "Enter the region for this cluster (us-west/eu-east) : " REGION_
#read -p "Enter the cpu type for this server (amd/intel) : " CPU_
#read -p "Enter the download speed of the connection in Mbps (1000) : " DOWNLOAD_
#read -p "Enter the upload speed of the connection in Mbps (250) : " UPLOAD_
#read -p "Enter the new keyring password to protect the wallet with (NewWalletPassword): " KEY_SECRET_

#Store securely for user
KEY_SECRET_=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)

#Depends / Microk8s / Kubectl / Helm
function depends(){
apt-get update && apt-get dist-upgrade -yqq ; apt-get install -y snapd sudo unzip cloud-utils open-vm-tools qemu-guest-agent bmon htop iotop jq bc nano snapd unzip sudo
snap install microk8s --classic ; snap install kubectl --classic ; snap install helm --classic
#mkdir -p ~/.kube ; microk8s config > ~/.kube/kubeconfig ; chmod 600 ~/.kube/kubeconfig ; export KUBECONFIG=~/.kube/kubeconfig
mkdir -p /home/akash/.kube ; microk8s config > /home/akash/.kube/kubeconfig
chmod 600 /home/akash/.kube/kubeconfig
chown akash:akash /home/akash/.kube/kubeconfig
export KUBECONFIG=/home/akash/.kube/kubeconfig
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
microk8s enable dns:1.1.1.1

#Install Akash and setup wallet
curl -sSfL https://raw.githubusercontent.com/ovrclk/akash/master/godownloader.sh | sh
cp bin/akash /usr/local/bin
rm -rf bin/
akash version

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
chown akash:akash *.sh

./run-helm-microk8s.sh
 
#Add/scale the cluster with 'microk8s add-node' and use the token on additional nodes.
#Use 'microk8s enable dns:1.1.1.1' after you add more than 1 node.

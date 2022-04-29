!/bin/bash
#This bootstrap makes some assumptions:
#1 : You have a working Kubernetes cluster and kubeconfig file.
#2 : A control machine to run this bootstrap from and control your new cluster.  The control machine needs all the dependencies in the depends function.
#3 : Update the Akash provider wallet settings before running.  You need to name NODE1 and NODE2 with the unique names your cluster uses. `microk8s kubectl get nodes`

export KUBECONFIG=./kubeconfig

#CLEANUP IF YOU NEED IT
#kubectl delete ns -l akash.network/lease.id.dseq
#helm uninstall -n akash-services akash-node || true
#helm uninstall -n akash-services akash-provider || true
#helm uninstall -n akash-services hostname-operator || true
#helm uninstall -n akash-services inventory-operator || true
#helm uninstall -n ingress-nginx akash-ingress || true
#kubectl delete ns akash-services
#kubectl delete ns ingress-nginx

###Akash Provider Wallet Settings
TYPE=blockchain #use setup to generate a certificate for the first time or blockchain to use a local certificate
DOMAIN="domainforakash.com"
ACCOUNT_ADDRESS=yourakashwalletaddress
KEY_SECRET="walletpasswordhere"
CHAIN_ID=akashnet-2
MONIKER=akt-computer-rpc #Unique name for your provider
CHAIN_ID=akashnet-2
REGION="us-west"
CHIA_PLOTTING=true #Has >1TB NVME storage in RAID0 and/or >512GB Memory
CPU="amd" #intel or amd
HOST="akash"
TIER="community"
ORG="any"
NODE=solo #shared or solo


if [[ $NODE == "shared" ]]
then
NODE="http://rpc.akash.world:26657"
else
NODE="http://akash-node-1:26657"
fi

helm repo add akash https://ovrclk.github.io/helm-charts
helm repo update

kubectl create ns akash-services
kubectl label ns akash-services akash.network/name=akash-services akash.network=true

kubectl create ns ingress-nginx
kubectl label ns ingress-nginx app.kubernetes.io/name=ingress-nginx app.kubernetes.io/instance=ingress-nginx

set -e
function node(){
helm upgrade --install akash-node ./helm-charts/charts/akash-node -n akash-services --set image.tag="0.16.4-rc0"
}
#node

helm upgrade --install akash-provider ./helm-charts/charts/akash-provider -n akash-services --set image.tag="0.16.4-rc0" \
             --set attributes[0].key=region --set attributes[0].value=$REGION \
             --set attributes[1].key=chia-plotting --set attributes[1].value=$CHIA_PLOTTING \
             --set attributes[2].key=host --set attributes[2].value=$HOST \
             --set attributes[3].key=cpu --set attributes[3].value=$CPU \
             --set attributes[4].key=tier --set attributes[4].value=$TIER \
             --set attributes[5].key=organization --set attributes[5].value=$ORG \
             --set attributes[6].key=network_download --set attributes[6].value="1000" \
             --set attributes[7].key=network_upload --set attributes[7].value="1000" \
             --set attributes[8].key=status --set attributes[8].value="https://updown.io/p/qmfr4" \
             --set from=$ACCOUNT_ADDRESS \
             --set key="$(cat ./key.pem | base64)" \
             --set keysecret="$(echo $KEY_SECRET | base64)" \
             --set serverpem="$(cat ./$ACCOUNT_ADDRESS.pem | base64)" \
             --set domain=$DOMAIN \
             --set node=$NODE \
             --set withdrawalperiod="0h5m" \
             --set gas=auto \
             --set type=$TYPE

helm upgrade --install hostname-operator akash/hostname-operator -n akash-services --set image.tag="0.16.4-rc0"
helm upgrade --install akash-ingress akash/akash-ingress -n ingress-nginx --set domain=$DOMAIN --set image.tag="0.16.4-rc0"

kubectl get node -o wide
kubectl get pods -o wide -n ingress-nginx
kubectl get pods -o wide -n akash-services
sleep 10
kubectl logs -f -n akash-services $(kubectl get pods -A | grep provider | awk '{print $2}')

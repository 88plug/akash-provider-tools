export KUBECONFIG=kubeconfig

#helm uninstall -n akash-services akash-provider || true

#function cleanup(){
#export KUBECONFIG=./kubeconfig
#helm uninstall -n akash-services akash-node || true
#helm uninstall -n akash-services akash-provider || true
#helm uninstall -n akash-services hostname-operator || true
#helm uninstall -n akash-services inventory-operator || true
#helm uninstall -n ingress-nginx akash-ingress || true
#kubectl delete ns akash-services --force --grace-period=0
#kubectl delete ns ingress-nginx --force --grace-period=0
#kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
#}
#cleanup

#TYPE=blockchain
#setup or blockchain
TYPE=blockchain
DOMAIN=
ACCOUNT_ADDRESS=
KEY_SECRET=
CHAIN_ID=akashnet-2
MONIKER=xeon-computer-rpc #Unique name for your provider
REGION="us-central" #us-east, us-west, eu-east, eu-west, etc
CHIA_PLOTTING=false #Set to true with NVME in RAID > 1TB
CPU="xeon"
HOST="akash"
TIER="community"
ORG="cryptoandcoffee"
NODE=solo #shared or solo

if [[ $NODE == "shared" ]]
then
NODE="http://135.181.181.122:28957"
#NODE="http://akash.c29r3.xyz:80/rpc"
#NODE="http://rpc.xch.computer:26657"
#NODE="http://rpc.akash.world:26657"
#NODE="http://rpc.sfo.computer:26657"
else
NODE="http://akash-node-1:26657"
fi

helm repo add akash https://ovrclk.github.io/helm-charts
helm repo update

#Required for cluster creation, do not edit.
kubectl create ns akash-services
kubectl label ns akash-services akash.network/name=akash-services akash.network=true

kubectl create ns ingress-nginx
kubectl label ns ingress-nginx app.kubernetes.io/name=ingress-nginx app.kubernetes.io/instance=ingress-nginx

function node(){
helm upgrade --install akash-node ./akash-helm-charts/charts/akash-node -n akash-services
}
#node

#helm upgrade --install --version $(curl https://api.github.com/repos/ovrclk/helm-charts/releases/latest -s | jq .name -r | cut -d"-" -f2) akash-provider akash/provider \
helm upgrade --install akash-provider ./akash-helm-charts/charts/akash-provider -n akash-services \
             --set attributes[0].key=region --set attributes[0].value=$REGION \
             --set attributes[1].key=chia-plotting --set attributes[1].value=$CHIA_PLOTTING \
             --set attributes[2].key=host --set attributes[2].value=$HOST \
             --set attributes[3].key=cpu --set attributes[3].value=$CPU \
             --set attributes[4].key=tier --set attributes[4].value=$TIER \
             --set attributes[5].key=organization --set attributes[5].value=$ORG \
             --set attributes[6].key=network_download --set attributes[6].value="1000" \
             --set attributes[7].key=network_upload --set attributes[7].value="1000" \
             --set attributes[8].key=status --set attributes[8].value="https://status.$DOMAIN" \
             --set from=$ACCOUNT_ADDRESS \
             --set key="$(cat ./key.pem | base64)" \
             --set keysecret="$(echo $KEY_SECRET | base64)" \
             --set serverpem="$(cat ./$ACCOUNT_ADDRESS.pem | base64)" \
             --set domain=$DOMAIN \
             --set node=$NODE \
             --set withdrawalperiod="12h" \
             --set gas=auto \
             --set type=$TYPE


helm upgrade --install hostname-operator ./akash-helm-charts/charts/hostname-operator -n akash-services
helm upgrade --install akash-ingress ./akash-helm-charts/charts/akash-nginx -n ingress-nginx --set domain=$DOMAIN


kubectl get node -o wide
kubectl get pods -o wide -n ingress-nginx
kubectl get pods -o wide -n akash-services
sleep 5
kubectl logs -f -n akash-services $(kubectl get pods -A | grep provider | grep Running | awk '{print $2}')

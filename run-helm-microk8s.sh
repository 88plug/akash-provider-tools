export KUBECONFIG=/var/snap/microk8s/current/credentials/client.config
. variables
#####################################################
DOMAIN="$DOMAIN"
ACCOUNT_ADDRESS="$ACCOUNT_ADDRESS"
KEY_SECRET="$KEY_SECRET"
CHAIN_ID=akashnet-2
REGION="$REGION"
CHIA_PLOTTING=false
CPU="$CPU"
HOST="akash"
TIER="community"
NODE="http://akash-node-1:26657"
#####################################################

helm repo add akash https://ovrclk.github.io/helm-charts
helm repo update

#Required for cluster creation, do not edit.
kubectl create ns akash-services
kubectl label ns akash-services akash.network/name=akash-services akash.network=true

kubectl create ns ingress-nginx
kubectl label ns ingress-nginx app.kubernetes.io/name=ingress-nginx app.kubernetes.io/instance=ingress-nginx

#When Github is working...
helm upgrade --install akash-node akash/akash-node -n akash-services --set image.tag=0.16.4 --set state_sync.enabled=true --set state_sync.rpc1="http://rpc.bigtractorplotting.com:26657" --set state_sync.rpc2="http://rpc.akt.computer:26657" --set peers="25057ddb321b3d389c11e62bd69da194938d5a9e@136.24.44.100:26656"

helm upgrade --install akash-provider akash/provider -n akash-services --set image.tag="0.16.4" \
             --set attributes[0].key=region --set attributes[0].value=$REGION \
             --set attributes[1].key=chia-plotting --set attributes[1].value=$CHIA_PLOTTING \
             --set attributes[2].key=host --set attributes[2].value=$HOST \
             --set attributes[3].key=cpu --set attributes[3].value=$CPU \
             --set attributes[4].key=tier --set attributes[4].value=$TIER \
             --set attributes[5].key=network_download --set attributes[5].value=$DOWNLOAD \
             --set attributes[6].key=network_upload --set attributes[6].value=$UPLOAD \
             --set attributes[7].key=status --set attributes[7].value=https://status.$DOMAIN \
             --set from=$ACCOUNT_ADDRESS \
             --set key="$(cat ./key.pem | base64)" \
             --set keysecret="$(echo $KEY_SECRET | base64)" \
             --set domain=$DOMAIN \
             --set bidpricescript="$(cat bid-engine-script.sh | openssl base64 -A)" \
             --set node=$NODE

helm upgrade --install hostname-operator akash/hostname-operator -n akash-services --set image.tag="0.16.4"
helm upgrade --install akash-ingress akash/akash-ingress -n ingress-nginx --set domain=$DOMAIN --set image.tag="0.16.4"

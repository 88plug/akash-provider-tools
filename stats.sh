#!/bin/bash
#Required Variables
##########################################################################################
##########################################################################################
##########################################################################################
#Provider monthly cost
export MONTHLY_COST=2000
export AKASH_NODE="http://192.168.1.223:26657"
export AKASH_ACCOUNT_ADDRESS=akash1wxr49evm8hddnx9ujsdtd86gk46s7ejnccqfmy
export local_node_ip="192.168.1.223"
export host="bigtractorplotting.com"
##########################################################################################
##########################################################################################
##########################################################################################
#Do Not Edit Below this Line
##########################################################################################
export AKASH_OUTPUT=json
export PROVIDER=$AKASH_ACCOUNT_ADDRESS
export AKASH_KEY_NAME=deploy
export AKASH_CHAIN_ID=akashnet-2
export AKASH_NET="https://raw.githubusercontent.com/ovrclk/net/master/mainnet"
export AKASH_NODE="$(curl -s "$AKASH_NET/rpc-nodes.txt" | shuf -n 1)"
export AKASH_CHAIN_ID="$(curl -s "$AKASH_NET/chain-id.txt")"

export KUBECONFIG=./kubeconfig


if ! command -v jq &> /dev/null
then
    echo "jq could not be found"
    exit
fi

if ! command -v bc &> /dev/null
then
    echo "bc could not be found"
    exit
fi


payouts(){

HEIGHT=$(akash query block | jq -r '.block.header.height')
akash query market lease list \
  --provider $PROVIDER \
  --gseq 0 --oseq 0 \
  --state active --page 1 --limit 5000 \
  | jq -r '.leases[].lease | [(.lease_id | .owner, (.dseq|tonumber), (.gseq|tonumber), (.oseq|tonumber), .provider)] | @tsv | gsub("\\t";",")' \
    | while IFS=, read owner dseq gseq oseq provider; do \
      REMAINING=$(akash query escrow blocks-remaining --dseq $dseq --owner $owner | jq -r '.balance_remaining')
      ## FOR DEBUGGING/INFORMATIONAL PURPOSES
      echo "INFO: $owner/$dseq/$gseq/$oseq balance remaining $REMAINING"

      if (( $(echo "$REMAINING < 0" | bc -l) )); then

        ( sleep 2s; cat key-pass.txt; cat key-pass.txt ) | akash tx market lease withdraw --provider $provider --owner $owner --dseq $dseq --oseq $oseq --gseq $gseq --gas-prices=0.025uakt --gas=auto --gas-adjustment=1.3 -y --from $provider
        sleep 1

      fi
      done
}
payouts

check_cluster(){




md_pfx="akash.network"
md_lid="$md_pfx/lease.id"
md_nsn="$md_pfx/namespace"

jqexpr="[.[\"$md_nsn\"],.[\"$md_lid.owner\"],.[\"$md_lid.dseq\"],.[\"$md_lid.gseq\"],.[\"$md_lid.oseq\"],.[\"$md_lid.provider\"]]"

nsdata(){
  kubectl get ns -l "$md_pfx=true,$md_lid.provider" \
    -o jsonpath='{.items[*].metadata.labels}'
}

ldata(){
  jq -rM "$jqexpr | @tsv"
}

nsdata | ldata | while read -r line; do
  ns="$(echo "$line" | awk '{print $1}')"
  owner="$(echo "$line" | awk '{print $2}')"
  dseq="$(echo "$line" | awk '{print $3}')"
  gseq="$(echo "$line" | awk '{print $4}')"
  oseq="$(echo "$line" | awk '{print $5}')"
  prov="$(echo "$line" | awk '{print $6}')"

  state=$(akash --node=$AKASH_NODE query market lease get --oseq 0 --gseq 0 \
    --owner "$owner" \
    --dseq  "$dseq" \
    --gseq  "$gseq" \
    --oseq  "$oseq" \
    --provider "$prov" \
    -o yaml \
    | jq -r '.lease.state' \
  )
  if [ "$state" == "active" ]; then
  echo "Found a lease with $owner"
  fi

  if [ "$state" == "closed" ]; then
    kubectl delete ns "$ns" --wait=false
    kubectl delete providerhosts -n lease \
      --selector="$md_lid.owner=$owner,$md_lid.dseq=$dseq,$md_lid.gseq=$gseq,$md_lid.oseq=$oseq" \
      --wait=false
  fi
done

}
check_cluster


##Get AKT Price
curl -s -X GET "https://api.coingecko.com/api/v3/coins/list" -H  "accept: application/json" > coingecko.log
line=$(cat coingecko.log | jq -cr '.[]  | select(.symbol == "akt") | .id' | head -n1)
curl -s -X GET "https://api.coingecko.com/api/v3/coins/${line}" > coingecko_dat.log
AKT_PRICE=$(cat coingecko_dat.log | jq -r '.market_data.current_price.usd')
AKT_PRICE=$(printf "%.4f" $AKT_PRICE)


while :
do

echo "####################"
echo "Health Check    "
echo "####################"
function health(){
echo "DNS Health Check"
[ "$(dig +short -t cname *.ingress.$host.)" ] && echo "DNS *.ingress.$host: *.ingress.$host. is valid"
[ "$(dig +short -t cname api.$host.)" ] && echo "DNS : api.$host. is valid" || echo "DNS : INVALID DNS CONFIGURATION!"
[ "$(dig +short -t cname grpc.$host.)" ] && echo "DNS : grpc.$host. is valid"
[ "$(dig +short -t A nodes.$host)" ] && echo "DNS : nodes.$host is valid"
[ "$(dig +short -t cname p2p.$host.)" ] && echo "DNS : p2p.$host. is valid"
[ "$(dig +short -t cname provider.$host.)" ] && echo "DNS : provider.$host. is valid"
[ "$(dig +short -t cname rpc.$host.)" ] && echo "DNS : rpc.$host. is valid"
}
health

echo Querying kubectl
kubectl get pods -A | grep -v akash-services | grep -v kube | grep -v ingress | wc -l > total_pods_running.log

if [[ $(cat ./total_pods_running.log) == $last ]]; then
echo "Skip"
else
rm message.log

echo "Querying the Akash blockchain for past leases on $AKASH_ACCOUNT_ADDRESS..."
earned_akt=$(akash query market lease list --node=$AKASH_NODE --provider $AKASH_ACCOUNT_ADDRESS --gseq 0 --oseq 0 --page 1 --limit 10000 -o json | jq -r '([.leases[].escrow_payment.withdrawn.amount|tonumber] | add) / pow(10;6)')
earned_usd=$(echo "scale=2 ; ($earned_akt * $AKT_PRICE)" | bc)
echo "Querying the Akash blockchain for leases on $AKASH_ACCOUNT_ADDRESS..."
akash query market lease list --node=$AKASH_NODE --provider $AKASH_ACCOUNT_ADDRESS --gseq 0 --oseq 0 --page 1 --limit 1000 --state active -o json | jq -r '["lease-owner","dseq","gseq","oseq","UAKT-block","monthly-AKT-estimate","monthly-USD-estimate", "daily-AKT-estimate", "daily-USD-estimate"], (.leases[] | [(.lease.lease_id | .owner, .dseq, .gseq, .oseq), (.escrow_payment | .rate.amount, (.rate.amount|tonumber), (.rate.amount|tonumber))]) | @csv' | awk -F ',' '{if (NR==1) {$1=$1; printf $0"\n"} else {$6=(($6*((60/6.706)*60*24*30.436875))/10^6); $7=(($7*((60/6.706)*60*24*30.436875))/10^6)*'${AKT_PRICE}'; $8=($6/30.436875); $9=($7/30.436875); print $0}}' | column -t > summary_leases.log

echo "-----------------------------------" >> message.log
echo "Leases Summary:" >> message.log
echo "-----------------------------------" >> message.log
cat summary_leases.log | tr -d '"' >> message.log
echo "-----------------------------------" >> message.log
echo "Paid Summary:" >> message.log
echo "-----------------------------------" >> message.log
echo "PAID $earned_usd in USD" >> message.log
echo "PAID $earned_akt in AKT" >> message.log
echo "-----------------------------------" >> message.log
echo "Income Summary:" >> message.log
echo "-----------------------------------" >> message.log
earning_usd=$(cat summary_leases.log | awk '{ sum+=$7} END {print sum}')
echo "Earning $(cat summary_leases.log | awk '{ sum+=$7} END {print sum}') per/month in USD" >> message.log
echo "Earning $(cat summary_leases.log | awk '{ sum+=$6} END {print sum}') per/month in AKT" >> message.log
echo "Earning $(cat summary_leases.log | awk '{ sum+=$8} END {print sum}') per/day in USD" >> message.log
echo "Earning $(cat summary_leases.log | awk '{ sum+=$9} END {print sum}') per/day in AKT" >> message.log
echo "-----------------------------------" >> message.log
echo "Profit Summary:" >> message.log
echo "-----------------------------------" >> message.log
profit=$(echo "scale=2 ; ($earning_usd - $MONTHLY_COST)" | bc)
echo "Monthly cost : $MONTHLY_COST" >> message.log
echo "Monthly profit estimate: $profit" >> message.log
echo "-----------------------------------" >> message.log
echo "Pod Summary:" >> message.log
echo "-----------------------------------" >> message.log
echo "The pod count has changed to $(cat ./total_pods_running.log)" >> message.log
last=$(cat ./total_pods_running.log)
leases=$(curl -s -k https://$local_node_ip:8443/status | jq -r .cluster.leases)
manifest_deployments=$(curl -s -k https://$local_node_ip:8443/status | jq -r .manifest.deployments)

echo "$host has $leases leases and $manifest_deployments manifest deployments" >> message.log
curl -s -k https://$local_node_ip:8443/status > current_status.log

active_memory=$(cat current_status.log | jq -r .cluster.inventory.active[].memory | awk '{ sum+=$1} END {print sum}')
active_cpu=$(cat current_status.log | jq -r .cluster.inventory.active[].cpu | awk '{ sum+=$1} END {print sum}')
active_storage=$(cat current_status.log | jq -r .cluster.inventory.active[].storage_ephemeral | awk '{ sum+=$1} END {print sum}')

available_memory=$(cat current_status.log | jq -r .cluster.inventory.available.nodes[].memory | awk '{ sum+=$1} END {print sum}')
available_cpu=$(cat current_status.log | jq -r .cluster.inventory.available.nodes[].cpu | awk '{ sum+=$1} END {print sum}')
available_storage=$(cat current_status.log | jq -r .cluster.inventory.available.nodes[].storage_ephemeral | awk '{ sum+=$1} END {print sum}')
echo "-----------------------------------" >> message.log
echo "Fill Rate Summary:" >> message.log
echo "-----------------------------------" >> message.log
fillrate_memory=$(awk -v A="$active_memory" -v B="$available_memory" 'BEGIN { print (A / (A + B)) * 100 ; exit 0}')
fillrate_cpu=$(awk -v A="$active_cpu" -v B="$available_cpu" 'BEGIN { print (A / (A + B)) * 100 ; exit 0}')
fillrate_storage=$(awk -v A="$active_storage" -v B="$available_storage" 'BEGIN { print (A / (A + B)) * 100 ; exit 0}')

fillrate_cpu=$(echo "scale=0 ; $fillrate_cpu" | bc)
fillrate_memory=$(echo "scale=0 ; $fillrate_memory" | bc)
fillrate_storage=$(echo "scale=0 ; $fillrate_storage" | bc)

echo "CPU      : ${fillrate_cpu}%" >> message.log
echo "Memory   : ${fillrate_memory}%" >> message.log
echo "Storage  : ${fillrate_storage}%" >> message.log

cat message.log
exit

fi
done



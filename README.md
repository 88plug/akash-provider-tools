# akash-provider-tools
A collection of tools for setting up / deploying / and managing Kubernetes clusters on Akash.Network


# Keep a small node / VPS clean of logs : requires bleachbit
`(crontab -l | grep -q '0 3 \* \* \* bleachbit --clean system.rotated_logs; bleachbit --clean system.cache; journalctl --vacuum-size=1M; bleachbit --clean apt.\*; k3s crictl rmi --prune' || (apt update && apt --assume-yes install bleachbit) && (crontab -l 2>/dev/null; echo '0 3 * * * bleachbit --clean system.rotated_logs; bleachbit --clean system.cache; journalctl --vacuum-size=1M; bleachbit --clean apt.*; k3s crictl rmi --prune') | crontab -)`

# Enable Security Updates on a node at 6:00am daily using a cronjob / run once during node setup:
`(crontab -l | grep -q "unattended-upgrades" || (crontab -l ; echo "0 6 * * * unattended-upgrades -d")) | crontab - && if ! dpkg -s unattended-upgrades >/dev/null 2>&1; then apt-get update && apt-get install -y unattended-upgrades; fi && if ! grep -qE '^\"\${distro_id}:\${distro_codename}-security\";' /etc/apt/apt.conf.d/50unattended-upgrades; then sed -i 's/^\/\/\s*\"\${distro_id}:\${distro_codename}-security\"/\"\${distro_id}:\${distro_codename}-security\"\;/' /etc/apt/apt.conf.d/50unattended-upgrades; fi && if ! grep -qE '^\"\${distro_id}:\${distro_codename}-updates\";\s*\"\${distro_id}:\${distro_codename}-security\";' /etc/apt/apt.conf.d/50unattended-upgrades; then sed -i 's/^\/\/\s*\"\${distro_id}:\${distro_codename}-updates\"/\"\${distro_id}:\${distro_codename}-updates\"\;\n\"\${distro_id}:\${distro_codename}-security\"\;/' /etc/apt/apt.conf.d/50unattended-upgrades; fi && unattended-upgrades -d`

# Run payouts on your provider - source code for the Docker is under Dockerfile-payouts
```
docker run -it -v key.pem:/key.pem --env PROVIDER=yourprovider.com --env PASS=replace_with_key_pass cryptoandcoffee/akash-provider-payout:1
```

# Deploy Akash RPC nodes one liner using Helm Charts. Set your DOMAIN= first.

```
DOMAIN=mydomain.com ; helm repo add akash https://ovrclk.github.io/helm-charts ; helm repo update ; kubectl create ns akash-services ; kubectl create ns ingress-nginx ; kubectl label ns ingress-nginx app.kubernetes.io/name=ingress-nginx app.kubernetes.io/instance=ingress-nginx ; helm upgrade --install akash-ingress akash/akash-ingress -n ingress-nginx --set domain=$DOMAIN ; helm upgrade --install akash-node akash/akash-node -n akash-services --set akash_node.api_enable=true --set akash_node.minimum_gas_prices=0uakt --set image.tag="0.16.4" --set state_sync.enabled=true
```

# Enable HPA - never let your provider / node / hostname-operator pods go down!  This will migrate them if a host fails.

```
#Setup HPA / Easy ! 

kubectl patch deployment -n akash-services akash-provider -p='{"spec":{"template":{"spec":{"containers":[{"name":"akash-provider","resources":{"requests":{"cpu":"4000m"}}}]}}}}'
kubectl patch deployment -n akash-services akash-node-1 -p='{"spec":{"template":{"spec":{"containers":[{"name":"akash-node","resources":{"requests":{"cpu":"1750m"}}}]}}}}'
kubectl patch deployment -n akash-services hostname-operator -p='{"spec":{"template":{"spec":{"containers":[{"name":"hostname-operator","resources":{"requests":{"cpu":"500m"}}}]}}}}'

#Default policy
kubectl autoscale deployment -n akash-services akash-provider --min=1 --max=10
kubectl autoscale deployment -n akash-services akash-node-1 --min=1 --max=10
kubectl autoscale deployment -n akash-services hostname-operator --min=1 --max=10

#Scale based on CPU Utilization - if you need it
#kubectl autoscale deployment -n akash-services akash-provider --cpu-percent=50 --min=1 --max=10
#kubectl autoscale deployment -n akash-services akash-node-1 --cpu-percent=50 --min=1 --max=10
#kubectl autoscale deployment -n akash-services hostname-operator --cpu-percent=50 --min=1 --max=10
```
# Cluster status monitoring

The best tool to use for cluster uptime monitoring is [UpDown.io](https://updown.io/r/ygC5V).  Here is a reference for how to configure your page: [status.akash.world.](https://status.akash.world).  Follow the instructions on UpDown to configure your status url to : `status.providerdomain.com`

# Remove a failed node from your cluster

# Change internal ip of microk8s node

On every node (including the master(s)):

    microk8s stop (Stop all nodes before changing configuration files)
    Get the VPN IP of the node, e.g. 10.x.y.z. Command ip a show dev tun1 will show info for interface tun1.
    Add this to the bottom of /var/snap/microk8s/current/args/kubelet:

--node-ip=10.x.y.z

    Add this to the bottom of /var/snap/microk8s/current/args/kube-apiserver:

--advertise-address=10.x.y.z

    microk8s start

Now I see the correct values in the INTERNAL-IP column with microk8s kubectl get nodes -o wide.


# Excessive kubernetes master pod restarts

https://platform9.com/kb/kubernetes/excessive-kubernetes-master-pod-restarts

Edit `nano /etc/etcd.env` and update `heartbeat-interval` and `election-timeout` to 100 and 1000.

# Enable DNS over TLS for Akash Provider / Cloudflare Secure DNS

On your Kubernetes cluster you need to update coredns with the Cloudflare config.

In a terminal with access to your cluster with kubectl:
```
KUBE_EDITOR="nano" kubectl edit cm coredns -n kube-system
```
Then change Forward to


        forward . tls://1.1.1.1 tls://1.0.0.1 {
        tls_servername tls.cloudflare-dns.com
        health_check 5s
        }

# Backup and Restore Akash Provider from Storj

Use Velero and Storj to create snapshot backups.

```
velero install --provider tardigrade \
    --plugins storjlabs/velero-plugin \
    --bucket provider-backups \
    --backup-location-config accessGrant=replaceme \
    --no-secret
```

## Backup command
`velero backup create $(hostname)`

## Restore command
`velero restore create --from-backup $(hostname)`

## Create a daily backup, each living for 90 days (2160 hours).
`velero create schedule $(hostname) --schedule="@every 24h" --ttl 2160h0m0s`

# Withdraw 
```
apt-get install -y bc jq
export AKASH_OUTPUT=json
export AKASH_NODE=http://
PROVIDER=

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

        ## UNCOMMENT WHEN READY
        ( sleep 2s; cat key-pass.txt; cat key-pass.txt ) | akash tx market lease withdraw --provider $provider --owner $owner --dseq $dseq --oseq $oseq --gseq $gseq --gas-prices=0.025uakt --gas=auto --gas-adjustment=1.3 -y --from $provider
        sleep 10
        ## TODO: sleep 10 is necessary as a safeguard against account sequence re-use.
        ## BUG: this script needs NOT to run at the same time provider withdraws the lease.

        ## FOR DEBUGGING PURPOSES, COMMENT WHEN READY
        #echo "INFO: akash tx market lease withdraw --provider $provider --owner $owner --dseq $dseq --oseq $oseq --gseq $gseq --gas-prices=0.025uakt --gas=auto --gas-adjustment=1.3 -y";

      fi
      done
```

# Run an Akash Provider with k3sup + zerotier + helm

1.  Setup mysql/postgres server 
2.  Setup zerotier account and create a new network
3.  Join the zerotier network on the machine you plan to run commands from (install plane)
3.  Install Ubuntu 22.04 on first server (full control plane)
4.  Install k3sup on install plane


Replace Server IP with zerotier IP
Change tls-san to your load balancer 
Change node-external-ip to the public IP of the node
Change node-ip to the $SERVER_IP
```
export SERVER_IP=172.22.x.x
export USER=root
export datastore="mysql://user:pass@tcp(dbserver:25060)/databasename"
k3sup install --ip $SERVER_IP --user $USER --datastore $datastore --token yoursupersecretokenthatnobodyknows --no-extras --tls-san balance.x.com --k3s-extra-args '--node-external-ip x.x.x.x --node-ip 172.22.x.x --flannel-iface ztyxa36bu3'
```
to add an agent - 
Install Ubuntu 22.04 and run
```
curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg' | gpg --import && \
if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z" | sudo bash; fi
zerotier-cli join YOURZEROTIERNETWORK
```

Replace AGENT_IP with zerotier IP

```
export AGENT_IP=172.22.x.x
export SERVER_IP=balance.bdl.computer
export USER=root

k3sup join --user $USER --ip $AGENT_IP --server-host $SERVER_IP --server-ip x.x.x.x --k3s-extra-args '--node-ip 172.22.x.x --flannel-iface ztyxa36bu3'
```

```



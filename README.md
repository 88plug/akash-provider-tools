# akash-provider-tools
A collection of tools for setting up / deploying / and managing Kubernetes clusters on Akash.Network

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

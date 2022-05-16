# Enable DNS over TLS for Akash Provider

On your Kubernetes cluster you need to update coredns with the Cloudflare config.

In a terminal with access to your cluster with kubectl, run:
`KUBE_EDITOR="nano" kubectl edit cm coredns -n kube-system`
Then change `Forward` to
```
        forward . tls://1.1.1.1 tls://1.0.0.1 {
        tls_servername tls.cloudflare-dns.com
        health_check 5s
        }
```

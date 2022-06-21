#!/bin/bash
curl https://raw.githubusercontent.com/88plug/akash-provider-tools/main/microk8s-bootstrap.sh
chmod +x microk8s-bootstrap.sh ; ./microk8s-bootstrap.sh
#Done, disable script on boot
systemctl disable akash ; rm /etc/systemd/system/akash.service

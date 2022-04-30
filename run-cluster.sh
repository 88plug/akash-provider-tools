#!/bin/bash
#This bootstrap makes some assumptions:
#1 : 3 new bare-metal servers/vps/vm's using Debian 11 / must have root user and ssh password login enabled.
#2 : A control machine with Debian 10/11 that will be seperate from the cluster. You will run this file from the control machine and use it to install Akash onto the cluster.
#3 : Update USER, SSHPASS, NODE1, NODE2, NODE3 with your servers info.  You can add as many nodes as you like, just use the same format. "export NODEX=x.x.x.x@password"
#set -e
###Server settings
USER=root #user on nodes to use/should be root.
export NODE1=192.168.1.12@akash
export NODE2=192.168.1.23@akash
export NODE3=192.168.1.34@akash
export NODE4=192.168.1.45@akash
###

declare -a IPS
readarray -t IPS <<<$(
  env |
    grep '^NODE[[:digit:]]\+=' | sort | cut -d= -f2
)
echo "using pools ${IPS[*]}"

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root!"
  exit
fi

COUNTER=0

function depends() {
  apt-get update
  apt-get install -y python3-pip git sshpass software-properties-common snapd curl rsync libffi-dev
  python3 -m pip install ansible
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  git clone https://github.com/kubernetes-sigs/kubespray.git
  cd kubespray
  git checkout v2.18.0
  pip3 install -r requirements.txt
}
depends

#Assign static IP to your Kubernetes Hosts and update the user and IP address below

if [[ -f nodes.log ]]; then rm nodes.log; fi
if [[ -f $HOME/.ssh/id_rsa ]]; then
  echo "Found SSH key on local machine"
  cat ~/.ssh/id_rsa.pub
else
  echo "Making an SSH key on control machine"
  ssh-keygen -t rsa -C $(hostname) -f "$HOME/.ssh/id_rsa" -P ""
  cat ~/.ssh/id_rsa.pub
fi

for HOST in "${IPS[@]}"; do
  COUNTER=$((COUNTER + 1))
  IP=$(echo $HOST | cut -d'@' -f1)
  PASS=$(echo $HOST | cut -d'@' -f2)

  if ping -c 1 $IP &>/dev/null; then
    echo "Found ping to $IP"
  else
    echo "All hosts not ready"
    exit
  fi

  echo $HOST
  echo $USER
  echo $IP
  echo $PASS
  echo $COUNTER
  export SSHPASS=$PASS
  echo $IP >>nodes.log

  if ssh -o BatchMode=yes -o ConnectTimeout=2 root@$IP exit; then
    echo "Found good connection with correct SSH to $IP"
  else
    ssh-keyscan $IP >>~/.ssh/known_hosts
    sshpass -e ssh-copy-id -i ~/.ssh/id_rsa.pub $USER@$IP
    ssh -n $USER@$IP "sed -i '/swap/ s/^/#/' /etc/fstab"
    ssh -n $USER@$IP echo "br_netfilter" >>/etc/modules
    ssh -n $USER@$IP hostnamectl set-hostname node${COUNTER}
    hostname -f
    ssh -n $USER@$IP "echo 127.0.1.1     node${COUNTER} > /etc/hosts ; cat /etc/hosts"
    ssh -n $USER@$IP reboot
  fi

done
unset SSHPASS
echo "All hosts rebooted, waiting for them to all come online"
sleep 3

printf "Waiting for $(cat nodes.log | tail -n1):22"
until nc -z $(cat nodes.log | tail -n1) 22 2>/dev/null; do
  printf 'Found port 22 alive!  Waiting 15 more seconds for things to settle down...'
  sleep 15
done
echo "up! Ready for Kubespraying!"

function ansible() {
  #Setup ansible
  cp -rfp inventory/sample inventory/akash
  #Create config.yaml
  CONFIG_FILE=inventory/akash/hosts.yaml python3 contrib/inventory_builder/inventory.py $(cat nodes.log | sed -e :a -e '$!N; s/\n/ /; ta')
  cat inventory/akash/hosts.yaml
  #Enable gvisor for security
  ex inventory/akash/hosts.yaml <<eof
2 insert
  vars:
    cluster_id: "1.0.0.1"
    ansible_user: root
    gvisor_enabled: true
.
xit
eof
  echo "File Modified"
  cat inventory/akash/hosts.yaml
}
ansible

function start_cluster() {
  #Run
  ansible-playbook -i inventory/akash/hosts.yaml -b -v --private-key=~/.ssh/id_rsa cluster.yml
  #Get the kubeconfig from master node
  rsync -av root@$(cat nodes.log | head -n1):/root/.kube/config kubeconfig
  #Use the new kubeconfig file for kubectl
  export KUBECONFIG=./kubeconfig
  #Get snap path right
  export PATH=$PATH:/snap/bin
  #Install kubectl and helm using snap
  snap install kubectl --classic
  snap install helm --classic
  #Change the name of the server address in kubeconfig to master
  sed -i "s/127.0.0.1/$(cat nodes.log | head -n1)/g" kubeconfig
  cp kubeconfig ../kubeconfig
  #Show the pods!
}
start_cluster

sleep 5
cd ..
export KUBECONFIG=./kubeconfig
kubectl get nodes -o wide

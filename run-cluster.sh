#!/bin/bash
#Quickstart!
#set -e
#Install depends on this machine
function depends(){
sudo apt-get update ; sudo apt-get install -y python3-pip git sshpass software-properties-common rsync snapd
add-apt-repository --yes --update ppa:ansible/ansible
sudo apt-get install -y ansible
git clone https://github.com/kubernetes-sigs/kubespray.git ; cd kubespray
pip3 install -r requirements.txt
}
depends
########################################################################################
#Assign static IP to your Kubernetes nodes and update the user and IP address below
export USER=root
export NODE1=x.x.x.x@rootpass
export NODE2=x.x.x.x@rootpass
export NODE3=x.x.x.x@rootpass
export NODE4=x.x.x.x@rootpass

echo "using pools ${IPS[*]}"

COUNTER=0
if [[ -f nodes.log ]]; then rm nodes.log; fi
#Create ssh keys to transfer to nodes
if [[ -f $HOME/.ssh/id_rsa ]]; then
echo "Found SSH key on local machine"
cat ~/.ssh/id_rsa.pub
else
ssh-keygen -t rsa -C $(hostname) -f "$HOME/.ssh/id_rsa" -P "" ; cat ~/.ssh/id_rsa.pub
fi

#function ssh(){
for HOST in "${IPS[@]}"
do
COUNTER=$(( COUNTER + 1 ))
#echo "Split"
IP=$(echo $HOST | cut -d'@' -f1)
PASS=$(echo $HOST | cut -d'@' -f2)

if ping -c 1 $IP &> /dev/null
then
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
echo $IP >> nodes.log
if ssh -o BatchMode=yes -o ConnectTimeout=2 root@$IP exit
then
echo "Found good connection with correct SSH to $IP"
else
ssh-keyscan $IP >> ~/.ssh/known_hosts
sshpass -e ssh-copy-id -i ~/.ssh/id_rsa.pub $USER@$IP
ssh -n $USER@$IP hostnamectl set-hostname node${COUNTER} ; hostname -f
ssh -n $USER@$IP "echo 127.0.1.1     node${COUNTER} > /etc/hosts ; cat /etc/hosts"
sed -i '/ swap / s/^/#/' /etc/fstab
echo "br_netfilter" >> /etc/modules
ssh -n $USER@$IP reboot
fi

done

echo "All hosts rebooted, waiting for them to all come online"
sleep 5
printf "Waiting for $(cat nodes.log | tail -n1):22"
until nc -z $(cat nodes.log | tail -n1) 22 2>/dev/null; do
    printf 'Found port 22 alive!  Waiting 15 more seconds for things to settle down...'
    sleep 15
done
echo "up! Ready for Kubespraying!"

function ansible(){
#Setup ansible
cp -rfp inventory/sample inventory/akash
#Create config.yaml
cat nodes.log
cat nodes.log | sed -e :a -e '$!N; s/\n/ /; ta'
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

function start_cluster(){
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
#Show the nodes!
export KUBECONFIG=./kubeconfig
kubectl get nodes -A
}
start_cluster

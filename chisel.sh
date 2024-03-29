#chisel to get through firewalls
#SERVER
#run on akash deployment/vps of your choise!
INSTALL CHISEL ON BOTH CLIENT AND SERVER - the install systemd services.

For VULTR VPS
ufw disable ; apt-get update ; apt-get dist-upgrade -yqq ; apt-get install -y golang ; go install github.com/jpillora/chisel@latest ; cp go/bin/chisel /usr/local/bin/ ; rm -rf go ; echo "Chisel installed"
For Debian 12
ufw disable ; apt-get update ; apt-get dist-upgrade -yqq ; apt-get install curl psmisc screen  ; curl https://i.jpillora.com/chisel! | bash 

SERVER/VPS SERVICE
---
[Unit]
Description=Chisel BDL Service
After=network.target

[Service]
ExecStartPre=/bin/bash -c "sleep 10" # optional: wait a bit for the network to be ready
ExecStart=/bin/bash -c 'chisel server --host 137.220.x.x --port 8000 --reverse -v --auth akash:strong_password'
Restart=always
User=root
Group=root
Environment=PATH=/usr/bin:/usr/local/bin:/sbin:/bin
KillMode=process

[Install]
WantedBy=multi-user.target

CLIENT SERVICE
---
[Unit]
Description=Chisel Client
After=network.target

[Service]
ExecStart=/usr/local/bin/chisel client -v --keepalive 1m --auth akash:strong_password 137.220.x.x:8000 R:137.220.x.x:80:localhost:80 R:137.220.x.x:443:localhost:443 R:137.220.x.x:1317:localhost:1317 R:137.220.x.x:26656:localhost:26656 R:137.220.x.x:26657:localhost:26657 R:137.220.x.x:8443:localhost:8443
Restart=always
User=akash

[Install]
WantedBy=multi-user.target

BONUS
----
run on akash-node1
----
#!/bin/bash

# Specify your server IP address and port
serverIP="137.220.x.x"
serverPort="8000"

# Specify your local IP address (change this if necessary)
localIP="localhost"

# Start building the command
command="chisel client -v --keepalive 10m $serverIP:$serverPort"

# Add the specific port forwards you mentioned
command+=" R:$serverIP:80:$localIP:80"
command+=" R:$serverIP:443:$localIP:443"
command+=" R:$serverIP:1317:$localIP:1317"
command+=" R:$serverIP:26656:$localIP:26656"
command+=" R:$serverIP:26657:$localIP:26657"
command+=" R:$serverIP:8443:$localIP:8443"

add_all(){

# Add each port in the range to the command
for port in {30000..32767}
do
    command+=" R:$serverIP:$port:$localIP:$port"
done
}
#add_all
#Adds ephemeral ports - VPS must have high memory.

# Print the resulting command
echo $command
----
Use screen to open all ports
----
#!/bin/bash
killall screen
killall chisel
# Specify your server IP address and port
serverIP="207.x.x.x"
serverPort="8000"

# Specify your local IP address (change this if necessary)
localIP="localhost"

add_range() {
    local start=$1
    local end=$2
    local command="chisel client -v --keepalive 10m --auth akash:strong_password $serverIP:$serverPort"

    for port in $(seq $start $end)
    do
        command+=" R:$serverIP:$port:$localIP:$port"
    done

    screen -dm bash -c "$command"
    sleep 10
}

# Start chisel command with the fixed ports
command="chisel client -v --keepalive 1m --auth akash:strong_password $serverIP:$serverPort"
command+=" R:$serverIP:80:$localIP:80"
command+=" R:$serverIP:443:$localIP:443"
command+=" R:$serverIP:1317:$localIP:1317"
command+=" R:$serverIP:26656:$localIP:26656"
command+=" R:$serverIP:26657:$localIP:26657"
command+=" R:$serverIP:8443:$localIP:8443"
screen -dm bash -c "$command"

#Start screens in chunks to not overwhelm memory
chunk_size=500
start=30000
end=32767

for (( i=$start; i<=$end; i+=$chunk_size ))
do
    # Use the minimum between i + chunk_size - 1 and the end value
    add_range $i $(($((i + chunk_size - 1))<$end?$((i + chunk_size - 1)):$end))
done


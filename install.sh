#!/bin/bash
#  
#  apt install -y curl && bash <(curl -s https://raw.githubusercontent.com/foudugame/Wings_KVM_AutoSSL/main/install.sh)
#
clear
echo "load ...."
sleep 2

if ! [ -x "$(command -v git)" ]; then
   apt update -y
   apt upgrade -y
   apt install -y curl git
fi

if ! [ -x "$(command -v sudo)" ]; then
   apt install -y sudo
fi

if [ -d "/etc/AutoSSL" ];then
   rm -r /etc/AutoSSL
fi

mkdir -p /etc/AutoSSL
tee /etc/AutoSSL/autossl.sh <<EOF
#!/bin/sh
startAPP() {
    export CF_Token="pkqSVxhthFX7B1i......."
    export CF_Account_ID="eb0d22cc1d......."
    export CF_Zone_ID="bf687fd701b2........"

    domaine="exemple.com"

    #sudo rm -r /etc/letsencrypt/live/\${domaine}
    mkdir -p /etc/letsencrypt/live/\${domaine}
    chmod 777 /etc/letsencrypt/live/\${domaine}

    cd /etc/AutoSSL

    git clone https://github.com/acmesh-official/acme.sh.git
    chmod 777 /etc/AutoSSL/acme.sh
    cd /etc/AutoSSL/acme.sh

    ./acme.sh --issue --dns dns_cf -d "\${domaine}" --server letsencrypt \\
    --key-file /etc/letsencrypt/live/\${domaine}/privkey.pem \\
    --fullchain-file /etc/letsencrypt/live/\${domaine}/fullchain.pem
}

case "\$1" in
        start)
                startAPP
                ;;
        stop)
                echo "Error commands"
                ;;
        restart)
                startAPP
                ;;
        reload)
                startAPP
                ;;
        status)
                echo "Error commands"
                ;;
        *)
                 startAPP
esac

EOF
chmod 777 -R /etc/AutoSSL
nano /etc/AutoSSL/autossl.sh

if [ ! -f "/lib/systemd/system/autossl.service" ];then
   tee /lib/systemd/system/autossl.service <<EOF
[Unit]
Description=AutoSSL...

[Service]
ExecStart=/etc/AutoSSL/autossl.sh
[Install]
WantedBy=multi-user.target
EOF
   systemctl enable --now autossl
   systemctl start autossl.service 
   systemctl daemon-reload
fi

if ! [ -x "$(command -v docker)" ]; then
   curl -sSL https://get.docker.com/ | CHANNEL=stable bash
   systemctl enable --now docker
   systemctl daemon-reload
fi

if [ ! -d "/tmp/Wings_KVM_AutoSSL" ];then
   mkdir -p  /tmp/Wings_KVM_AutoSSL
fi

if [ ! -d "/etc/pterodactyl" ];then
   mkdir -p /etc/pterodactyl
fi

if [ ! -f "/tmp/Wings_KVM_AutoSSL/wings.tar.001" ];then
   curl -sSLo /tmp/Wings_KVM_AutoSSL/wings.tar.001 https://github.com/foudugame/Wings_KVM_AutoSSL/raw/main/wings.tar.001
fi

if [ ! -f "/tmp/Wings_KVM_AutoSSL/wings.tar.002" ];then
   curl -sSLo /tmp/Wings_KVM_AutoSSL/wings.tar.002 https://github.com/foudugame/Wings_KVM_AutoSSL/raw/main/wings.tar.002
fi

if [ -f "/usr/local/bin/wings" ];then
   rm -rf /usr/local/bin/wings
fi

if [ -f "/tmp/Wings_KVM_AutoSSL/wings.tar.001" ];then
   if [ -f "/tmp/Wings_KVM_AutoSSL/wings.tar.002" ];then
       cat /tmp/Wings_KVM_AutoSSL/wings.tar.* > /tmp/Wings_KVM_AutoSSL/wingsUnPack.tar
       tar -xvf /tmp/Wings_KVM_AutoSSL/wingsUnPack.tar -C /usr/local/bin
       rm -R /tmp/Wings_KVM_AutoSSL
       chmod u+x /usr/local/bin/wings
   fi
fi


if [ -f "/dev/kvm" ];then
   chmod 777 /dev/kvm
fi


if [ ! -f "/lib/systemd/system/wings.service" ];then
   tee /lib/systemd/system/wings.service <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
   
   systemctl enable --now wings
   systemctl daemon-reload
fi

exit
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.all.forwarding=0
sudo sysctl -w net.ipv4.ip_forward=1
sudo echo 1 > /proc/sys/net/ipv4/ip_forward

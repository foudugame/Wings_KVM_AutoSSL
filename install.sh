#!/bin/bash
#  
#  apt install -y curl && bash <(curl -s https://raw.githubusercontent.com/foudugame/Wings_KVM_AutoSSL/main/install.sh)
#
clear
echo "load ...."
sleep 2
read -r -p "${1:-Voulez-vous mettre à jour le système avant ? [y/N]} " op1
case "$op1" in
    [yY][eE][sS]|[yY]) 
        apt update -y
        apt upgrade -y
		clear
        ;;
    *)
esac

clear
echo -e "# ========================================================================="
echo -e "# Installations"
echo -e "# ========================================================================="
echo -e ""
echo -e " 1 - Installer Wings/kvm (default)"
echo -e " 2 - Activer le certificate (SSL)"
echo -e " 3 - Désactiver le certificate (SSL)"

read -r -p "${1:-Voulez-vous mettre à jour le système avant ? [y/N]} " op2
if [ "$op2" == "2" ]; then
   _add_ssl
   exit
fi

if [ "$op2" == "3" ]; then
   /usr/bin/sed -i 's/enabled: false/enabled: true/' /etc/pterodactyl/config.yml
   /usr/bin/systemctl restart wings
   exit
fi

if ! [ -x "$(command -v git)" ]; then
   apt install -y curl git
fi

if ! [ -x "$(command -v qemu-kvm)" ]; then
   apt install -y qemu-kvm
   grep kvm /etc/group
   adduser $USER kvm
fi

if ! [ -x "$(command -v sudo)" ]; then
   apt install -y sudo
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

function _add_ssl(){

	if [ "${DOMAIN}" == "" ]; then
        read -p "Domaine (SSL): " DOMAIN
		exit
    fi

    if [ "${EMAIL}" == "" ]; then
       read -p "Email domaine: " EMAIL
	   exit
    fi

    certbot -d $DOMAIN -m $EMAIL --manual --preferred-challenges dns certonly
    certbot certificates
	
    if [ ! -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" ];then
	    read -p "Erreur certbot aucuns certificates!"
        _add_ssl		
		exit
    fi
	
    if [ ! -f "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" ];then
        read -p "Erreur certbot aucuns certificates!"
        _add_ssl
		exit
    fi
	
    /usr/bin/sed -i 's/cert: .*/cert: \/etc\/letsencrypt\/live\/'${DOMAIN}'\/fullchain.pem/' /etc/pterodactyl/config.yml
    /usr/bin/sed -i 's/key: .*/key: \/etc\/letsencrypt\/live\/'${DOMAIN}'\/privkey.pem/' /etc/pterodactyl/config.yml
    /usr/bin/sed -i 's/enabled: false/enabled: true/' /etc/pterodactyl/config.yml
    /usr/bin/sed -i 's/allowed_origins:.*/allowed_origins: ["'${DOMAIN}'"]/' /etc/pterodactyl/config.yml

    echo -e "# ========================================================================="
    echo -e "# Configuration Cron"
    echo -e "# ========================================================================="
    echo -e ""
    echo -e "Par exemple, pour que le script s'exécute à 2 h 00 du matin tous les jours, nous ouvririons cron avec la commande suivante :"
    echo -e "Et ajoutez la ligne suivante à cron :"
    echo -e ""	
    echo -e "crontab -e"
    echo -e ""
    echo -e "0 2 * * * certbot renew --quiet --deploy-hook \"systemctl restart wings\""
    echo -e ""
    read -p "Press any key to resume ..."
	nano /etc/pterodactyl/config.yml
	/usr/bin/systemctl restart wings
}

read -r -p "${1:-Installer le certificate au wings (SSL)? [y/N]} " SSLADD
case "$SSLADD" in
    [yY][eE][sS]|[yY]) 
        _add_ssl
        ;;
    *)
esac

exit
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.all.forwarding=0
sudo sysctl -w net.ipv4.ip_forward=1
sudo echo 1 > /proc/sys/net/ipv4/ip_forward

test2.the-bandit.ovh
mail@test2.the-bandit.ovh

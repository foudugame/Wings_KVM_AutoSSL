if [ -d "/home/neaj/dossier1" ];then
   rm -r /etc/AutoSSL
fi
mkdir -p /etc/AutoSSL
tee /etc/AutoSSL/AutoSSL.sh <<EOF
startAPP() {
    echo "
    export CF_Token="pkqSVxhthFX7B1i......."
    export CF_Account_ID="eb0d22cc1d......."
    export CF_Zone_ID="bf687fd701b2........"

    domaine="exemple.com"

    #sudo rm -r /etc/letsencrypt/live/${domaine}
    mkdir -p /etc/letsencrypt/live/${domaine}
    chmod 777 /etc/letsencrypt/live/${domaine}

    cd /etc/AutoSSL

    git clone https://github.com/acmesh-official/acme.sh.git
    chmod 777 /etc/AutoSSL/acme.sh
    cd /etc/AutoSSL/acme.sh

    ./acme.sh --issue --dns dns_cf -d "${domaine}" --server letsencrypt \
    --key-file /etc/letsencrypt/live/${domaine}/privkey.pem \
    --fullchain-file /etc/letsencrypt/live/${domaine}/fullchain.pem
}

case "$1" in
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
nano /etc/AutoSSL/AutoSSL.sh
systemctl enable --now AutoSSL

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

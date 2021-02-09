# Check if we already installed the server
# Real.96 & Energy
if [ -f /etc/.dwc_installed ]; then
    echo "You already installed dwc_network_server_emulator. There is no need to re-run this script."
    echo "In you want to UPDATE your actual installation, the best way is to nuke your system and re-install everything with this script"
    echo "And if you wish to uninstall everything, just nuke your system."
    exit 999
fi
# ensure running as root
if [ "$(id -u)" != "0" ]; then
    exec sudo "$0" "$@"
fi

# We will test internet connectivity using ping
if ping -c 2 github.com >/dev/nul; then
    echo "Internet is OK"
elif ping -c 2 torproject.org >/dev/nul; then
    echo "Internet is OK"
else
    echo "Internet Connection Test Failed!"
    echo "If you want to bypass internet check use -s arg!"
    exit 1
fi

shopt -s extglob # Fix rm -- !() error
mkdir /var/www/
cd /var/www/

# We'll create our secret locale file
touch /var/www/.locale-done

# Variables used by the script in various sections to pre-fill long commandds
C1="0"            # A counting variable
IP=""             # Used for user input

# Functions

function build_nginx_openssl() {
	wget https://www.openssl.org/source/openssl-1.0.2u.tar.gz
	wget http://nginx.org/download/nginx-1.19.6.tar.gz
	tar xf nginx-1.19.6.tar.gz
	chmod 777 nginx-1.19.6
	rm nginx-1.19.6.tar.gz
	tar xf openssl-1.0.2u.tar.gz
	chmod 777 openssl-1.0.2u
	rm openssl-1.0.2u.tar.gz
	cd nginx-1.19.6/
	./configure --with-http_ssl_module --with-openssl=/var/www/openssl-1.0.2u --with-openssl-opt=enable-ssl3 --with-openssl-opt=enable-ssl3-method --with-openssl-opt=enable-weak-ssl-ciphers
	make
	make install
	cd /var/www
	rm -r openssl-1.0.2u
	rm -r nginx-1.19.6
}

function create_nginx_vh_nintendo() {
	# This function will create virtual hosts for Nintendo's domains in Nginx
    echo "Creating Nintendo virtual hosts...."
	if [ -f /etc/lsb-release ]; then
		if grep -q "14.04" /etc/lsb-release; then
			echo "Creating Nintendo virtual hosts...."
			touch /etc/nginx/sites-available/dwc-hosts
			cat >/etc/nginx/sites-available/dwc-hosts <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name gamestats.gs.nintendowifi.net gamestats2.gs.nintendowifi.net;
    location / {
        proxy_set_header X-Forwarded-Host \$host:\$server_port;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_pass http://127.0.0.1:9002;
    }
}

server {
    listen 443;
    listen [::]:443;
    ssl on;
    ssl_protocols SSLv3;
    ssl_ciphers RC4-SHA:RC4-MD5;
    ssl_certificate /var/www/ssl/server-chain.crt;
    ssl_certificate_key /var/www/ssl/server.key;
    server_name naswii.nintendowifi.net nas.nintendowifi.net conntest.nintendowifi.net;
    underscores_in_headers on;
    proxy_pass_request_headers on;
    location / {    
        proxy_set_header X-Forwarded-Host \$host:\$server_port;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_pass http://127.0.0.1:9000;
    }
}

server {
    listen 80;
    listen [::]:80;
    server_name sake.gs.nintendowifi.net *.sake.gs.nintendowifi.net secure.sake.gs.nintendowifi.net *.secure.sake.gs.nintendowifi.net;
    location / {
        proxy_set_header X-Forwarded-Host \$host:$server_port;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_pass http://127.0.0.1:8000;
    }
}

server {
    listen 443;
    listen [::]:443;
    ssl on;
    ssl_protocols SSLv3;
    ssl_ciphers RC4-SHA:RC4-MD5;
    ssl_certificate /var/www/ssl/server-chain.crt;
    ssl_certificate_key /var/www/ssl/server.key;
    server_name dls1.nintendowifi.net;
    underscores_in_headers on;
    proxy_pass_request_headers on;
    location / {
        proxy_set_header X-Forwarded-Host \$host:\$server_port;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_pass http://127.0.0.1:9003;
    }
}
EOF

			echo "Done!"
			echo "enabling..."
			sudo ln -s /etc/nginx/sites-available/dwc-hosts /etc/nginx/sites-enabled
			service nginx restart	
		else
			rm /usr/local/nginx/conf/nginx.conf
			touch /usr/local/nginx/conf/nginx.conf
			cat >/usr/local/nginx/conf/nginx.conf <<EOF

worker_processes  1;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    keepalive_timeout  65;

    server {
        listen       80;
        server_name  localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }

    server {
        listen 80;
        listen [::]:80;
        server_name gamestats.gs.nintendowifi.net gamestats2.gs.nintendowifi.net;
        location / {
            proxy_set_header X-Forwarded-Host \$host:\$server_port;
            proxy_set_header X-Forwarded-Server \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_pass http://127.0.0.1:9002;
        }
    }

    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        ssl_protocols SSLv3;
        ssl_ciphers RC4-SHA:RC4-MD5;
        ssl_certificate /var/www/ssl/server-chain.crt;
        ssl_certificate_key /var/www/ssl/server.key;
        server_name naswii.nintendowifi.net nas.nintendowifi.net conntest.nintendowifi.net;
        underscores_in_headers on;
        proxy_pass_request_headers on;
        location / {    
            proxy_set_header X-Forwarded-Host \$host:\$server_port;
            proxy_set_header X-Forwarded-Server \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_pass http://127.0.0.1:9000;
        }
    }

    server {
        listen 80;
        listen [::]:80;
        server_name sake.gs.nintendowifi.net *.sake.gs.nintendowifi.net secure.sake.gs.nintendowifi.net *.secure.sake.gs.nintendowifi.net;
        location / {
            proxy_set_header X-Forwarded-Host \$host:\$server_port;
            proxy_set_header X-Forwarded-Server \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_pass http://127.0.0.1:8000;
        }
    }

    server {
        listen 443 ssl;
        listen [::]:443 ssl;
        ssl_protocols SSLv3;
        ssl_ciphers RC4-SHA:RC4-MD5;
        ssl_certificate /var/www/ssl/server-chain.crt;
        ssl_certificate_key /var/www/ssl/server.key;
        server_name dls1.nintendowifi.net;
        underscores_in_headers on;
        proxy_pass_request_headers on;
        location / {
            proxy_set_header X-Forwarded-Host \$host:\$server_port;
            proxy_set_header X-Forwarded-Server \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_pass http://127.0.0.1:9003;
        }
    }
}
EOF

			echo "Done!"
			echo "enabling..."
			cd /usr/local/nginx/sbin/
			./nginx
			cd /var/www
		fi
	fi
}

function dns_config() {
	if [ -f /etc/lsb-release ]; then
		if grep -q "18.04" /etc/lsb-release || grep -q "20.04" /etc/lsb-release; then
			cat >>/etc/dnsmasq.conf <<EOF
bind-interfaces
EOF
		fi
	fi
    # This function will configure dnsmasq
    echo "----------Lets configure DNSMASQ now----------"
    sleep 1s
    echo "Your LAN IP is"
    hostname -I | cut -f1 -d' '
    echo "Please type in your LAN IP"
    read -re IP
    cat >>/etc/dnsmasq.conf <<EOF # Adds your IP you provide to the end of the DNSMASQ config file
address=/nintendowifi.net/$IP
EOF
    echo "DNSMasq setup completed!"
    clear
    service dnsmasq restart
    clear
}

function install_required_packages() {
    echo "Installing required packages..."
    # Fix dpkg problems that happened somehow
    dpkg --configure -a
    apt-get update
    # Add required package requires packages
	apt-get install python2.7 dnsmasq git net-tools wget libpcre3 libpcre3-dev zlib1g zlib1g-dev -y
	if [ -f /etc/lsb-release ]; then
		if grep -q "14.04" /etc/lsb-release; then
			apt-get install nginx -y
		fi
		if grep -q "20.04" /etc/lsb-release; then
			wget https://bootstrap.pypa.io/2.7/get-pip.py
			chmod 777 get-pip.py
			python2.7 get-pip.py
			rm get-pip.py
			pip install twisted
		else
			apt-get install python-twisted -y
		fi
	fi
}

function generate_certificates() {
	echo "Generating certificate files..."
	mkdir /var/www/ssl/
	cd /var/www/ssl/
	wget https://larsenv.github.io/NintendoCerts/WII_NWC_1_CERT.p12
	openssl pkcs12 -in WII_NWC_1_CERT.p12 -passin pass:alpine -passout pass:alpine -out NWC.key -nodes -nocerts
	openssl pkcs12 -in WII_NWC_1_CERT.p12 -passin pass:alpine -passout pass:alpine -out NWC.crt -nodes -nokeys
	openssl genrsa -out server.key 1024
	openssl req -new -key server.key -out server.csr << EOF
EU
Italy
Rome
Nintendo of Italy Inc.
.
*.*.*
ro@nintendo.net
.
.
EOF
	openssl x509 -req -in server.csr -CA NWC.crt -CAkey NWC.key -CAcreateserial -out server.crt -days 3650 -sha1
	cat server.crt NWC.crt > server-chain.crt
	rm -- !("server-chain.crt"|"server.key")
	cd /var/www/
}

# MAIN
# Put commands or functions on these lines to continue with script execution.
# The first thing we will do is to update our package repos but let's also make sure that the user is running the script in the proper directory /var/www
if [ "$PWD" == "/var/www" ]; then
    apt-get update
    # Let's install required packages first.
    install_required_packages
    # Let's generate required certificates.
    generate_certificates
	if ! grep -q "14.04" /etc/lsb-release; then
		# Build Nginx with OpenSSL
		build_nginx_openssl
	fi
    # Let's set up Nginx now
    create_nginx_vh_nintendo
    # Configure DNSMASQ
    dns_config
    # Then we will check to see if the Gits dwc_network_server_emulator exist
    if [ ! -d "/var/www/dwc_network_server_emulator" ]; then
        echo "Git for dwc_network_server_emulator does not exist in /var/www"
        while ! git clone https://github.com/barronwaffles/dwc_network_server_emulator.git && [ "$C1" -le "4" ]; do
            echo "GIT CLONE FAILED! Retrying......"
            ((C1 = C1 + 1))
        done
        if [ "$C1" == "5" ]; then
            echo "Giving up"
            exit 1
        fi
		# Let's make our hidden file so that our script will know that we've already installed the server
		# This will prevent accidental re-runs
		echo "Finishing..."
		touch /etc/.dwc_installed
		echo "Thank you for installing dwc_network_server_emulator!"
        echo "Setting proper file permissions"
        chmod 777 /var/www/dwc_network_server_emulator/ -R
		cd /var/www/dwc_network_server_emulator
		python2.7 master_server.py
		cd /
    fi
# DO NOT PUT COMMANDS UNDER THIS FI
fi
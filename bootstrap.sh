#!/bin/bash

echo "Defining ENV variables"
# Postfix
OEMAIL=youremail@domain.tld
AEMAIL=alert@domain.tld
DOMAIN=dev.local
MAILER="Satellite system"
RELAYHOST=smtp.domain.tld
EPSW=YOUR-PASSWORD

# Ports / IP
SSHPORT=22
HTTPPORT=8080
HTTPSPORT=8043
DBPORT=3306
IP=192.168.10.10

# https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
echo "Defining TZ data, check https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
TZDATA="Europe/Rome"

# MariaDB users
# root user
DBROOTUSER=root
DBROOTPSW=rootpass

# super user
DBSUSER=super
DBSPSW=superpass

# local user
DBLUSER=super
DBLPSW=superpass

# db name
DBNAME=wpdev

echo "Ready ..."
echo "Steady ..."
echo "GO!"
echo "I've got superpowers!"
sudo -i

echo "Updating repositories"
apt-get update

echo "Setting up TZDATA previously defined"
echo $TZDATA | tee /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

echo "Installing NTP"
export DEBIAN_FRONTEND=noninteractive
apt-get install ntpdate -y
cd /etc/cron.daily/
touch ntpdate
echo '#!/bin/bash' | tee --append ntpdate
echo 'ntpdate ntp.ubuntu.com' | tee --append ntpdate
chmod a+x ntpdate
./ntpdate

echo "Setting up LOCALE"
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
locale-gen en_US.UTF-8
dpkg-reconfigure locales

echo "Updating /etc/hosts file"
echo '$IP dev.local' | tee --append /etc/hosts

echo "Installing PHP's lib"
apt-get install -y php7.2 php7.2-cli php7.2-cgi php7.2-curl php7.2-mysql php7.2-gd php7.2-xmlrpc php7.2-fpm mcrypt

echo "Creating selfsigned SSL certificate"
mkdir /etc/nginx/
mkdir /etc/nginx/ssl/
openssl req -x509 -out /etc/nginx/ssl/dev.local.crt -keyout /etc/nginx/ssl/dev.local.key -newkey rsa:2048 -nodes -sha256 -subj '/CN=dev.local' -extensions EXT -config <(printf "[dn]\nCN=dev.local\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:dev.local\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")
openssl req -x509 -out /etc/nginx/ssl/dev-wp.local.crt -keyout /etc/nginx/ssl/dev-wp.local.key -newkey rsa:2048 -nodes -sha256 -subj '/CN=dev-wp.local' -extensions EXT -config <(printf "[dn]\nCN=dev-wp.local\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:dev-wp.local\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")

echo "Installing NginX"
apt-get install -y nginx
cp /usr/local/config/web/nginx/dev.local /etc/nginx/sites-available/
cp /usr/local/config/web/nginx/dev-wp.local /etc/nginx/sites-available/
cd /etc/nginx/sites-enabled/ && ln -s ../sites-available/dev.local dev.local
cd /etc/nginx/sites-enabled/ && ln -s ../sites-available/dev-wp.local
cp /usr/local/config/web/nginx/nginx.conf /etc/nginx/
rm -rf /etc/nginx/sites-available/default
rm -rf /etc/nginx/sites-enabled/default

echo "Installing MariaDB client"
apt-get install -y mariadb-client

echo "Presetting configuration for MariaDB server"
debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password password $DBROOTPSW'
debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password_again password $DBROOTPSW'

echo "Installing MariaDB 10.1"
apt-get install mariadb-server-10.1 -y

echo "Caricamento della nuova configurazione di MariaDB"
cp /usr/local/config/data/mariadb/50-server.cnf /etc/mysql/mariadb.conf.d/
service mysql reload
service mysql start

echo "Creating MariaDB superuser and local user"
echo "CREATE USER '$DBSUSER'@'%' IDENTIFIED BY '$DBSPSW';" | mysql -u$DBROOTUSER -p$DBROOTPSW
echo "GRANT ALTER, CREATE, CREATE VIEW, CREATE USER, ALTER ROUTINE, CREATE ROUTINE, CREATE TEMPORARY TABLES, DELETE, DROP, EVENT, GRANT OPTION, INDEX, INSERT, LOCK TABLES, PROCESS, REFERENCES, RELOAD, SELECT, SHOW DATABASES, SHOW VIEW, SUPER, TRIGGER, UPDATE ON *.* TO '$DBSUSER'@'%';" | mysql -u$DBROOTUSER -p$DBROOTPSW
echo "CREATE USER '$DBLUSER'@'$IP' IDENTIFIED BY '$DBLPSW';" | mysql -u$DBROOTUSER -p$DBROOTPSW
echo "GRANT CREATE, SELECT, INSERT, UPDATE, DELETE, EXECUTE ON *.* TO '$DBLUSER'@'$IP';" | mysql -u$DBROOTUSER -p$DBROOTPSW
echo "flush privileges;" | mysql -u$DBROOTUSER -p$DBROOTPSW

echo "Creating DB: $DBNAME"
echo "CREATE DATABASE IF NOT EXISTS $DBNAME;" | mysql -u$DBROOTUSER -p$DBROOTPSW

echo "Installing Postfix"
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<E
'postfix postfix/root_address string $OEMAIL'
E
debconf-set-selections <<E
'postfix postfix/main_mailer_type string $MAILER'
E
debconf-set-selections <<E
'postfix postfix/mailname string $DOMAIN'
E
debconf-set-selections <<E
'postfix postfix/relayhost string $RELAYHOST'
E

apt-get install -y postfix > /dev/null

touch /etc/postfix/sasl_passwd
echo "$RELAYHOST $OEMAIL:$EPSW" | tee /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd
postmap hash:/etc/postfix/sasl_passwd

echo "Updating /etc/postfix/main.cf"
echo 'sender_dependent_relayhost_maps = hash:/etc/postfix/relayhost_maps' | tee --append /etc/postfix/main.cf
echo 'smtp_sasl_auth_enable = yes' | tee --append /etc/postfix/main.cf
echo 'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd' | tee --append /etc/postfix/main.cf
echo 'smtp_sasl_security_options = noanonymous' | tee --append /etc/postfix/main.cf
echo 'smtp_use_tls = yes' tee --append /etc/postfix/main.cf

touch /etc/postfix/relayhost_maps
echo "$AEMAIL [$RELAYHOST]" | tee /etc/postfix/relayhost_maps
postmap hash:/etc/postfix/relayhost_maps
service postfix reload
service postfix restart
newaliases

echo "Creating iptables rules"
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport $SSHPORT -j ACCEPT
iptables -A INPUT -p tcp --dport $HTTPPORT -j ACCEPT
iptables -A INPUT -p tcp --dport $HTTPSPORT -j ACCEPT
iptables -I INPUT -p tcp -s $IP --dport $DBPORT -j ACCEPT
iptables -A INPUT -j DROP
iptables-save

echo "Storing iptables rules"
bash -c "iptables-save > /etc/iptables.rules"
cd /etc/network/if-pre-up.d/
cp /usr/local/config/web/iptables/iptablesload .
cd /etc/network/if-down.d/
cp /usr/local/config/web/iptables/iptablessave .
chmod +x /etc/network/if-pre-up.d/iptablesload
chmod +x /etc/network/if-down.d/iptablessave

echo "Reload all services"
service php7.2-fpm force-reload
service php7.2-fpm restart
pkill nginx
service nginx force-reload
service nginx restart
service mysql reload
service mysql restart

echo "Done"
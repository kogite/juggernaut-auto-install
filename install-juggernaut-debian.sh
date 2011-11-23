#! /bin/sh
#
# A lancer en root
#
#
clear
echo '################################################################'
echo ''
echo 'Installation NodeJs - NPM - Node_Redis - PHP-Redis - Juggernaut'
echo 'NodeJs : v0.6.0'
echo 'Redis : v2.4.2'
echo ''
echo 'Référence du Wiki - des sites - du blog'
echo '################################################################'
#
# ToDo :
#	- mettre des couleurs
#	- prévoir le cas Debian / CentOS
#

# Variables
# Versions
VNODE='0.6.0'
VREDIS='2.4.2'

REPINST=/root/install/juggernaut
IP=$(/sbin/ifconfig eth0 | grep "inet adr" | awk '{print $2}' | awk -F: '{print $2}')

# Préparation du serveur
if [ ! -d /root/install/juggernaut ] 
	then
	mkdir -p $REPINST
fi

# Vérification des pré-requis
echo 'Vérification des pré-requis'

# Séparer apache2 & php5 ?

LISTDEP="build-essential 
subversion 
php5-dev 
curl 
git 
python 
libssl-dev 
apache2 
php5"

for DEP in $LISTDEP
do
dpkg -l | grep -e '^ii' | grep $DEP > /dev/null 2>&1
if [ $? -eq 1 ]
	then
	# echo "Installation du paquet $DEP"
	echo $DEP	
	echo '[A INSTALLER]'
	TOINSTALL="${TOINSTALL} ${DEP}"
	# apt-get install $DEP

else
	echo '[DEJA INSTALLE]'
fi
done

echo $TOINSTALL 

# Uniquement pour les tests
exit

apt-get install $TOINSTALL

# Installation des pré-requis
echo 'Installation des pré-requis'

# Installation de Nodejs
echo 'Installation de Nodejs'
cd $REPINST
wget http://nodejs.org/dist/v$VNODE/node-v$VNODE.tar.gz
tar xzf node-v$VNODE.tar.gz
cd node-v$VNODE
./configure
make -j2
make install

# Installation de NPM
echo 'Installation de NPM'
cd $REPINST
curl http://npmjs.org/install.sh | sh

# Installation de Redis
echo 'Installation de Redis'
cd $REPINST
wget http://redis.googlecode.com/files/redis-$VREDIS.tar.gz
tar xzf redis-$VREDIS.tar.gz
cd redis-$VREDIS
make
make install
mkdir /etc/redis
cd /etc/redis
wget https://raw.github.com/gist/1164482/77e4ecf14ffac42b0e987e7ffe16cb757d734ff9/redis.conf

# Installation de Node_redis
echo 'Installation de Node_redis'
npm install redis

# Installation de PHP-Redis
echo 'Installation de PHP-Redis'
cd $REPINST
# Vérifier la version - Git ?
git clone https://github.com/owlient/phpredis.git $REPINST/phpredis
cd phpredis
phpize
./configure
make && make install

if [ ! -f /etc/php5/conf.d/redis.ini ]
	then
	touch /etc/php5/conf.d/redis.ini
	echo 'extension=redis.so' > /etc/php5/conf.d/redis.ini
fi

# Installation de Juggernaut
echo 'Installation de Juggernaut'
npm install -g juggernaut

# Scripts de démarrage Redis-Server/Juggernaut
echo 'Installation des scripts de démarrage automatique de Redis-Server & Juggernaut'
	# Redis-server : Attention coquille dans DAEMON redis-server
	cd /etc/init.d
	# wget http://www.systea.net/public/juggernaut/redis-server
	chmod +x /etc/init.d/redis-server
	useradd redis  
	mkdir -p /var/lib/redis  
	mkdir -p /var/log/redis  
	chown redis.redis /var/lib/redis  
	chown redis.redis /var/log/redis
	update-rc.d redis-server defaults
	# Juggernaut
	cd /etc/init.d
	# wget http://www.systea.net/public/juggernaut/juggernaut
	adduser --system --no-create-home --disabled-login --disabled-password --group juggernaut
	chmod +x /etc/init.d/juggernaut
	update-rc.d -f juggernaut defaults

# Post-Install.
# Copie des samples PHP-Juggernaut
cd /var/www
mkdir /var/www/juggernaut 
if [ ! -d /var/www/juggernaut ] 
	then
	mkdir -p /var/www/juggernaut
fi

# git kogite
wget http://www.systea.net/public/

# http://@IP/juggernaut/index.php
# /etc/init.d/redis-server {start|stop|restart} - /etc/init.d/juggernaut {start|stop|restart}

# Suppression des fichiers d'installation
echo 'Suppression des fichiers d'installation'
rm -rf $REPINST

# Redémarrage du service apache2
echo 'Redémarrage du service Apache'
/etc/init.d/apache2 reload
/etc/init.d/apache2 restart

# Démarrage des services
echo 'Démarrage des services redis-server & juggernaut'
/etc/init.d/redis-server start
/etc/init.d/juggernaut start

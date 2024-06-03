#!/bin/sh

# Ajout du dépôt PostgreSQL
sudo apt install curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc

deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt ubuntu-pgdg main
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

sudo apt update
sudo apt install postgresql-16
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt bionic-pgdg main" >> /etc/apt/sources.list'
sudo apt-get install --reinstall ca-certificates
wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc |sudo sudo apt-key add -
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update

# Installation de PostgreSQL, PostGIS et pgRouting
sudo apt install -y postgresql-11 postgresql-11-postgis-2.5 postgresql-11-pgrouting

# Configuration de l'utilisateur système postgres
sudo passwd postgres

# Connexion à PostgreSQL pour configurer l'utilisateur
sudo su - postgres -c "psql -c \"ALTER ROLE postgres ENCRYPTED PASSWORD 'mot_de_passe';\""

# Modification des fichiers de configuration PostgreSQL pour permettre les connexions à distance
POSTGRESQL_CONF="/etc/postgresql/11/main/postgresql.conf"
PG_HBA_CONF="/etc/postgresql/11/main/pg_hba.conf"

sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" $POSTGRESQL_CONF
echo "host all all 0.0.0.0/0 md5" | sudo tee -a $PG_HBA_CONF

# Redémarrage de PostgreSQL pour appliquer les modifications
sudo service postgresql restart

# Installation de Java Runtime et unzip
sudo apt install -y openjdk-8-jre unzip

# Installation de GeoServer
GEOSERVER_DIR="/var/www/geoserver"
sudo mkdir -p $GEOSERVER_DIR
cd $GEOSERVER_DIR
sudo wget https://netcologne.dl.sourceforge.net/project/geoserver/GeoServer/2.15.2/geoserver-2.15.2-bin.zip
sudo unzip geoserver-2.15.2-bin.zip
sudo mv geoserver-2.15.2/* .
echo "export GEOSERVER_HOME=$GEOSERVER_DIR" >> ~/.profile
source ~/.profile

# Démarrage de GeoServer
cd $GEOSERVER_DIR/bin
sudo sh startup.sh

# Création d'un utilisateur système pour GeoServer
sudo adduser --system geoserver
sudo chown -R geoserver $GEOSERVER_DIR/data_dir $GEOSERVER_DIR/logs
sudo chmod -R o+rX $GEOSERVER_DIR

# Création du fichier de service systemd pour GeoServer
GEOSERVER_SERVICE="/etc/systemd/system/geoserver.service"
sudo bash -c "cat > $GEOSERVER_SERVICE" <<EOL
[Unit]
Description=GeoServer
After=network.target

[Service]
User=geoserver
Environment=JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
Environment=GEOSERVER_HOME=$GEOSERVER_DIR
ExecStart=$GEOSERVER_DIR/bin/startup.sh
ExecStop=$GEOSERVER_DIR/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOL

# Activation et démarrage du service GeoServer
sudo systemctl enable geoserver.service
sudo systemctl start geoserver.service

echo "Installation et configuration de PostgreSQL, PostGIS, pgRouting et GeoServer terminées."
echo "Vous pouvez vérifier GeoServer à l'adresse suivante : http://adresse_ip_de_votre_serveur:8080/geoserver/web"

chmod +x install_postgresql_geoserver.sh
sudo ./install_postgresql_geoserver.sh



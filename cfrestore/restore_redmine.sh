#
# Use:
#   REDMINE_BASE para el nombre base del redmine. Default: redmine2
#   REDMINE_DBPASS para el password del mysql. Default 
#	REDMINE_PORT para el puerto. Default 10443
#
pushd data
BASENAME=${REDMINE_BASE:-redmine2}
REDMINEPORT=${REDMINE_PORT:-10443}
MYSQLPASS=${REDMINE_DBPASS:-Cf2017mYF}
REDMINECONTAINER=$BASENAME
MYSQLCONTAINER=mysql$BASENAME
REDMINEDIR=$BASENAME

GZIPFILENAME=backup_redmine.tar.gz


#
# Borra
#
docker rm -f $REDMINECONTAINER
docker rm -f $MYSQLCONTAINER
# echo Waiting after remove
# sleep 5

rm -rf /srv/$REDMINEDIR

set -e

#
# Restore de los archivos
#
mkdir /srv/$REDMINEDIR
sudo tar -xzvf $GZIPFILENAME -C /srv/$REDMINEDIR

#
# Lanza MySql
#
docker run -d --name $MYSQLCONTAINER --health-cmd='mysqladmin ping --silent'  --restart=always -e MYSQL_ROOT_PASSWORD=$MYSQLPASS -e MYSQL_DATABASE=redmine mysql:5.7

while [ $(docker inspect --format "{{json .State.Health.Status }}" $MYSQLCONTAINER) != "\"healthy\"" ]; do printf "."; sleep 1; done

# Restaura la base de datos MySql
pushd /srv/$REDMINEDIR

cat backup.sql | docker exec -i $MYSQLCONTAINER /usr/bin/mysql -u root --password=$MYSQLPASS redmine
rm -f backup.sql
popd 

# Crea el container
docker run -d --name $REDMINECONTAINER -v /srv/$REDMINEDIR/data:/usr/src/redmine/files -v /srv/$REDMINEDIR/certs:/usr/src/redmine/certs -p $REDMINEPORT:3443 -e PASSENGER_SSL=true -e PASSENGER_SSL_CERTIFICATE=/usr/src/redmine/certs/redminecfsa.pem -e PASSENGER_SSL_CERTIFICATE_KEY=/usr/src/redmine/certs/redminecfsa.key -e PASSENGER_SSL_PORT=3443 --link $MYSQLCONTAINER:mysql redmine:3.4-passenger

echo waiting 20 seconds
sleep 20

#
# Restaura los directorios internos al container
#
docker cp  /srv/$REDMINEDIR/container/config $REDMINECONTAINER:/usr/src/redmine
docker cp  /srv/$REDMINEDIR/container/plugins $REDMINECONTAINER:/usr/src/redmine

# Reinicia el container.
sudo docker restart $REDMINECONTAINER

popd

set -e
pushd data
REDMINECONTAINER=redminecf
MYSQLCONTAINER=mysqlredmine1
REDMINEDIR=redmine
MYSQLPASS=Cf2017mYF
TARFILENAME=backup_redmine.tar
GZIPFILENAME=backup_redmine.tar.gz

echo Entering SuperUser
#
# Backup de la base de datos MySql
#
docker exec $MYSQLCONTAINER /usr/bin/mysqldump -u root --password=$MYSQLPASS redmine > backup.sql

#
# Backup de directorios internos del container
#
echo copiando container/config
sudo docker cp $REDMINECONTAINER:/usr/src/redmine/config /srv/$REDMINEDIR/container
echo copiando container/plugins
sudo docker cp $REDMINECONTAINER:/usr/src/redmine/plugins /srv/$REDMINEDIR/container

#
# Backup de los directorios locales con data y certificados
#
CURDIR=$PWD
pushd /srv/$REDMINEDIR 
sudo tar -cvf $CURDIR/$TARFILENAME certs/ data/ container/
popd

# Le agrega el backup.sql y el script de backup.
sudo tar -uvf $TARFILENAME backup.sql ../backup_redmine.sh

rm -f backup.sql
sudo gzip -f $TARFILENAME

popd



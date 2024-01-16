#!/bin/sh

# https://dev.mysql.com/doc/refman/8.0/en/mysql-cluster-install-docker.html
# Script creates a MySQL database cluster with 1 manager node,
# 1 MySQL node and 2 data nodes

# NEW_PASSWORD set in a config file
# DATABASE_SCHEMA set in a config file
# source ./config.sh

export DATABASE_SCHEMA="test_db"

# check if script is run as root
if [ "${EUID}" -ne 0 ];
  then 
          echo "Please run skript as root."
          exit 1
fi


# change dns server to doogle dns
sed -i '1inameserver 8.8.8.8' /etc/resolv.conf


# check if docke network 'dbcluster' already exists
echo "Checking if docker network 'dbcluster' on subnet 192.168.0.0 exists..."
if docker network ls | grep dbcluster > /dev/null
# network exists
then
        echo "Docker network 'dbcluster' already exists"
# network doesn't exists
else
        docker network create dbcluster --subnet=192.168.0.0/16
fi


# pull docker image
echo ""
echo "Pulling docker image"
docker pull container-registry.oracle.com/mysql/community-cluster
echo ""


# create manager node
echo "Creating management node"
docker run -d --net=dbcluster --name=mgm1 --ip=192.168.0.2 \
        --volume="./cnf/my.cnf":"/etc/my.cnf" \
        --volume="./cnf/mysql-cluster.cnf":"/etc/mysql-cluster.cnf" \
        container-registry.oracle.com/mysql/community-cluster ndb_mgmd
echo "Management node created"
echo ""


# create data nodes
echo "Creating data nodes"
docker run -d --net=dbcluster --name=ndb1 --ip=192.168.0.3 \
        container-registry.oracle.com/mysql/community-cluster ndbd
docker run -d --net=dbcluster --name=ndb2 --ip=192.168.0.4 \
        container-registry.oracle.com/mysql/community-cluster ndbd
#docker run -d --net=dbcluster --name=ndb3 --ip=192.168.0.5 \
#        container-registry.oracle.com/mysql/community-cluster ndbd
echo "Data nodes created"
echo ""


#  create mysql server node
echo "Creating MySQL node"
docker run -d --net=dbcluster --name=mysql1 --ip=192.168.0.10 -e MYSQL_RANDOM_ROOT_PASSWORD=true \
        container-registry.oracle.com/mysql/community-cluster mysqld
echo "MySQL node created"
echo ""


# initialise PASSWORD variable
PASSWORD=""
# wait for Password to be set, i.e. wait for containers to be ready then
while [ -z "${PASSWORD}" ]
do
        echo -ne "Waiting for containers to be up and running...\r"
        sleep 1s
        # PASSWORD=$(docker logs mysql1 2>&1 | grep PASSWORD)
        PASSWORD_AUTO=$(echo "$(docker logs mysql1 2>&1 | grep PASSWORD)" | awk '{print $NF}')
done
# get password for mysql1 container and print to console
echo ""
echo "Containers are up and running"
# echo "${PASSWORD}"
export PASS=$PASSWORD_AUTO
cat ./populate_db.txt | docker exec -i mysql1 mysql --user=root --password=${PASS}


# instructions for mysql1 MySQL node
#echo ""
#echo "Currently running on MySQL node, command used:"
#echo "> docker exec -it mysql1 mysql -uroot -p"
#echo "Command to change password to itsadmin:"
#echo "> ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_PASSWORD}';"
#echo "Command to create schema test_db"
#echo "> CREATE SCHEMA ${DATABASE_SCHEMA};"
#echo ""
# open mysql1 MySQL container to inject commands
#docker exec -it mysql1 mysql -uroot -p
# populate database test_db immediately after exiting
echo "Database ${DATABASE_SCHEMA} is now being populated..."
#cat ./populate_db.txt | docker exec -i mysql1 mysql --user=root --password=${NEW_PASSWORD} --database=${DATABASE_SCHEMA}
echo "Database successfully populated"
echo ""


# instructions for mgmt1 manager node
#echo ""
#echo "Currently running on manager node, command used:"
#echo "> docker exec -it mgmt1 ndb_mgm"
#echo "Use SHOW command for ndb_mgm"
#echo ""
# open mgmt1 manager container to manage database
#docker exec -it mgm1 ndb_mgm


echo ""
echo "###################################################"
echo "                       DONE!                       "
echo "###################################################"
echo ""

exit 0

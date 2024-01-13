#!/bin/sh

# Script creates a MySQL database cluster
# https://dev.mysql.com/doc/refman/8.0/en/mysql-cluster-install-docker.html

# change dns server
sed -i '1inameserver 8.8.8.8' /etc/resolv.conf

echo "Checking if docker network 'dbcluster' on subnet 192.168.0.0 exists..."

# check if network exists
if docker network ls | grep dbcluster > /dev/null
# network exists
then
        echo "Docker network 'dbcluster' already exists"
# network doesn't exists
else
        docker network create --subnet=192.168.0.0/16
fi

# pull docker image
echo ""
echo "Pulling docker image"
docker pull container-registry.oracle.com/mysql/community-cluster
echo ""

# create manager node
echo "Creating management node"
docker run -d --net=dbcluster --name=mgmt1 --ip=192.168.0.2 \
        container-registry.oracle.com/mysql/community-cluster ndb_mgmd
echo "Management node created"
echo ""

# create data nodes
echo "Creating data nodes"
docker run -d --net=dbcluster --name=ndb1 --ip=192.168.0.3 \
        container-registry.oracle.com/mysql/community-cluster ndbd

docker run -d --net=dbcluster --name=ndb2 --ip=192.168.0.4 \
        container-registry.oracle.com/mysql/community-cluster ndbd
echo "Data nodes created"
echo ""

#  create mysql server node
echo "Creating MySQL node"
docker run -d --net=dbcluster --name=mysql1 --ip=192.168.0.10 -e MYSQL_RANDOM_ROOT_PASSWORD=true \
        container-registry.oracle.com/mysql/community-cluster mysqld
echo "MySQL node created"
echo ""


# get password for mysql1
PASSWORD=$(docker logs mysql1 2>&1 | grep PASSWORD)


# do while containers are not running
while [ 1 ]
do
        if [ "$PASSWORD" = "" ]
        then
                echo -ne "Waiting for containers to be up and running...\r"
                sleep 1s
                PASSWORD=$(docker logs mysql1 2>&1 | grep PASSWORD)
        else
                echo ""
                echo "Containers are up and running"
                echo "${PASSWORD}"
                break
        fi
done


# instructions for continuation
echo ""
echo "Currently running on MySQL node, command used:"
echo "> docker exec -it mysql1 mysql -uroot -p"
echo "Command to change password:"
echo "> ALTER USER 'root'@'localhost' IDENTIFIED BY 'itsadmin';"
echo ""

# open MySQL container to inject commands
docker exec -it mysql1 mysql -uroot -p


echo ""
echo "Currently running on manager node, command used:"
echo "> docker exec -it mgmt1 ndb_mgm"
echo "Use SHOW command for ndb_mgm"
echo ""

# open Manager container to manage database
docker exec -it mgmt1 ndb_mgm


echo ""
echo "####################"
echo "#####  DONE!  ######"
echo "####################"
echo ""

exit 1

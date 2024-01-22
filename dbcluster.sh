#!/bin/sh

# https://dev.mysql.com/doc/refman/8.0/en/mysql-cluster-install-docker.html
# Script creates a MySQL database cluster with 1 manager node,
# 1 MySQL node and 2 data nodes


# database schema can be changed, here it needs to be #test_db' as dummy data
# uses this schema
MAX_DATA_NODES=4

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
echo "Creating $DATA_NODES data nodes"
NODE_NAME=1
while [ $NODE_NAME -lt $MAX_DATA_NODES ]
do
  echo ""
  NODE_IP=$NODE_NAME + 2
  docker run -d --net=dbcluster --name=ndb${NODE_NAME} --ip=192.168.0.${NODE_IP} \
        container-registry.oracle.com/mysql/community-cluster ndbd

  echo "ndb${NODE_NAME} created!"
  echo ""
done
echo "Data nodes created"
echo ""


#  create mysql server node
echo "Creating MySQL node"
docker run -d --net=dbcluster --name=mysql1 --ip=192.168.0.10 -e MYSQL_RANDOM_ROOT_PASSWORD=true \
        container-registry.oracle.com/mysql/community-cluster mysqld
echo "MySQL node created"
echo ""


# MySQL Server generates a password automatically, following function pulls
# the password from docker logs and sets PASSWORD_AUTO variable value to
# that of the auto-generated password
# initialise PASSWORD_AUTO variable
PASSWORD_AUTO=""
# wait for Password to be set, i.e. wait for containers to be ready then
while [ -z "${PASSWORD_AUTO}" ]
do
        echo -ne "Waiting for containers to be up and running...\r"
        sleep 1s
        PASSWORD_AUTO=$(docker logs mysql1 2>&1 | grep PASSWORD)
done
PASSWORD_AUTO=$(echo "$(docker logs mysql1 2>&1 | grep PASSWORD)" | awk '{print $NF}')
echo ""
echo "Containers are up and running"


# populate database
echo "Database ${DATABASE_SCHEMA} is now being created and populated..."
echo "Waiting 10 seconds..."
sleep 10s
# injects SQL commands from populate_db.txt into mysql1 container to populate database
cat ./dummy_data.txt | docker exec -i mysql1 mysql --user=root --password=${PASSWORD_AUTO}
echo "Database successfully populated"
echo ""



echo ""
echo "###################################################"
echo "                       DONE!                       "
echo "###################################################"
echo ""

exit 0

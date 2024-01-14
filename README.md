# Scripts for creating a MySQL Cluster
[mysql-cluster-install-docker](https://dev.mysql.com/doc/refman/8.0/en/mysql-cluster-install-docker.html)

__Cluster will be created on one machine only due to personal hardware limitations__
__Cluster on different machines will be implemented later__



## Starting and running containers
To set-up and run the cluster, run the __dbcluster.sh__ script as root

Cluster is standard and will contain 1 manager node (mgmt1), 1 MySQL node (mysql1) and 2 data nodes (ndb1, ndb2)

dbcluster.sh does the following
- create a docker network called dbcluster on subnet 192.168.0.0/16
- pull the required docker image (container-registry.oracle.com/mysql/community-cluster)
- set up the 4 containers needed for the cluster
- print auto-generated password for mysql1 and command needed to change password
- attach mysql1 container to terminal (manual input needed here, i.e. copy password and use it to login, then copy command to change password)
- user neededs to exit container
- mgmt1 container will be automatically attached
- commands for management can now be used to monitor cluster (e.g. SHOW)


## Commands to populate newly created database
Commands to populate database can be run from a text files. 

dbcluster.sh will automatically run command after exiting mysql1 container for the first time


## if more nodes are needed

[mysql-cluster-files](https://github.com/mysql/mysql-docker/tree/mysql-cluster/8.0)
Link provides configuration files for MySQL Cluster 8.0.

After pulling repository, mysql-cluster.cnf file should be edited to reflect wanted cluster


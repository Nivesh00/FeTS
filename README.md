# Scripts for creating a MySQL Cluster

__Cluster will be created on one machine only due to personal hardware limitations__
__Cluster on different machines will be implemented later__

## Commands to populate newly created database


```sql
CREATE SCHEMA test_db;
```
```sql
CREATE TABLE test_db.fullname (id BIGINT NOT NULL AUTO_INCREMENT, fullname VARCHAR(20) NOT NULL, PRIMARY KEY (id));
```
```sql
INSERT INTO test_db.fullname (fullname) VALUES("Max Musterman"), ("Denise Louis"), ("Leoni Radermann"), ("Marc Müller"), ("Lucas Doppler");
```
```sql
SELECT * FROM test_db.fullname;
```

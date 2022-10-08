#!/bin/bash

mongo_version="4.2"

echo 'version: "3"
services:
  mongo1:
    hostname: mongo1
    container_name: localmongo1
    image: mongo:4.2
    expose:
    - 27011
    ports:
      - 127.0.0.1:27011:27011
    restart: always
    volumes:
      - mongov1:/data/db
      - /etc/localtime:/etc/localtime:ro
    entrypoint: [ "/usr/bin/mongod", "--port", "27011", "--bind_ip_all", "--replSet", "rs0" ]
  mongo2:
    hostname: mongo2
    container_name: localmongo2
    image: mongo:4.2
    expose:
    - 27012
    ports:
      - 127.0.0.1:27012:27012
    restart: always
    volumes:
      - mongov2:/data/db
      - /etc/localtime:/etc/localtime:ro
    entrypoint: [ "/usr/bin/mongod", "--port", "27012", "--bind_ip_all", "--replSet", "rs0" ]
  mongo3:
    hostname: mongo3
    container_name: localmongo3
    image: mongo:4.2
    expose:
    - 27013
    ports:
      - 127.0.0.1:27013:27013
    restart: always
    volumes:
      - mongov3:/data/db
      - /etc/localtime:/etc/localtime:ro
    entrypoint: [ "/usr/bin/mongod", "--port", "27013", "--bind_ip_all", "--replSet", "rs0" ]

volumes:
  mongov1:
  mongov2:
  mongov3:

' | sed "s|mongo:4.2|mongo:$mongo_version|g" > docker-compose.yml

sudo docker-compose up -d 

while true
do
echo "wait for container creation"
msg=$(docker exec -it localmongo1 mongo --port 27011 --eval \
'rs.initiate(
  {
    _id : "rs0",
    members: [
      { _id : 0, host : "mongo1:27011" },
      { _id : 1, host : "mongo2:27012" },
      { _id : 2, host : "mongo3:27013" }
    ]
  }
  )')

  if [[ "$msg" == *'refused'* ]]
  then
	  echo "wait 10 seconds"
	  sleep 10
  else
	  break
  fi 
done

echo "$msg"

while true
do
echo "wait for replica init"
msg=$(docker exec -it localmongo1 mongo --port 27011 --eval \
'admin = db.getSiblingDB("admin");
admin.createUser({ user: "admin",
                   pwd: "admin",
                   roles: [ { role: "root", db: "admin" } ] 
                   });')

  if [[ "$msg" == *'PRIMARY'* ]] || [[ "$msg" == *'already exists'* ]]
  then
    break
  else
    echo "wait 10 seconds"
    sleep 10
  fi 
done

echo "$msg"


if [[ -z "$(grep -ni mongo3 /etc/hosts)" ]]
then
	echo '127.0.0.1	mongo1 mongo2 mongo3' | sudo tee -a /etc/hosts
fi

echo "init replica key file"
echo "$(docker exec -it localmongo1 openssl rand -base64 756)" | sudo tee mongo-key
#openssl rand -base64 756 > mongo-key
sudo chmod 700 mongo-key

docker-compose down

echo 'version: "3"
services:
  mongo1:
    hostname: mongo1
    container_name: localmongo1
    image: mongo:4.2
    expose:
    - 27011
    ports:
      - 127.0.0.1:27011:27011
    restart: always
    volumes:
      - mongov1:/data/db
      - /etc/localtime:/etc/localtime:ro
      - ./mongo-key:/etc/mongo-key:ro
    entrypoint: [ "/usr/bin/mongod","--auth", "--keyFile" ,"/etc/mongo-key", "--port", "27011", "--bind_ip_all", "--replSet", "rs0" ]
  mongo2:
    hostname: mongo2
    container_name: localmongo2
    image: mongo:4.2
    expose:
    - 27012
    ports:
      - 127.0.0.1:27012:27012
    restart: always
    volumes:
      - mongov2:/data/db
      - /etc/localtime:/etc/localtime:ro
      - ./mongo-key:/etc/mongo-key:ro
    entrypoint: [ "/usr/bin/mongod","--auth", "--keyFile" ,"/etc/mongo-key", "--port", "27012", "--bind_ip_all", "--replSet", "rs0" ]
  mongo3:
    hostname: mongo3
    container_name: localmongo3
    image: mongo:4.2
    expose:
    - 27013
    ports:
      - 127.0.0.1:27013:27013
    restart: always
    volumes:
      - mongov3:/data/db
      - /etc/localtime:/etc/localtime:ro
      - ./mongo-key:/etc/mongo-key:ro
    entrypoint: [ "/usr/bin/mongod","--auth", "--keyFile" ,"/etc/mongo-key", "--port", "27013", "--bind_ip_all", "--replSet", "rs0" ]

volumes:
  mongov1:
  mongov2:
  mongov3:

' | sed "s|mongo:4.2|mongo:$mongo_version|g" > docker-compose.yml


sudo docker-compose up -d 


echo 'To use locally add record to your hosts
echo "127.0.0.1 mongo1 mongo2 mongo3" | sudo tee -a /etc/hosts

use this uri:
mongodb://admin:admin@mongo1:27011,mongo2:27012,mongo3:27013/db-name?replicaSet=rs0

connect with container shell:
docker exec -it localmongo1 mongo "mongodb://admin:admin@mongo1:27011,mongo2:27012,mongo3:27013/?replicaSet=rs0"

connect local mongo shell by:
mongo "mongodb://admin:admin@mongo1:27011,mongo2:27012,mongo3:27013/?replicaSet=rs0"

mongodump --uri="mongodb://admin:admin@mongo1:27011,mongo2:27012,mongo3:27013/?replicaSet=rs0" [additional options]

mongorestore --uri="mongodb://admin:admin@mongo1:27011,mongo2:27012,mongo3:27013/?replicaSet=rs0" [additional options]

...
'

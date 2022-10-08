# mongoDB

script for better using mongoDB

## create mongo replica set no auth

```bash
./mongo-docker-replicaset.sh
```

## create secure mongo replica set

```bash
./mongo-docker-replicaset-secure.sh
```

## create secure mongo replica set without arbiter node (2 secondaries)

```bash
./mongo-docker-replicaset-secure-no-arbiter.sh
```

## Local usage

For using with local applications or shell add following record to /etc/hosts

```bash
127.0.0.1 mongo1 mongo2 mongo3
```

to easy add run

```bash
echo "127.0.0.1 mongo1 mongo2 mongo3" | sudo tee -a /etc/hosts
```

## image version
You can change mongo image version 
and pull the image before running script
here it's like:

docker pull mongo:4.2

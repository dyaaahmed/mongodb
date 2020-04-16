#!/bin/bash
#This script dump mongodb containers

# Defining vars 
CONTAINER_NAME="$(docker ps | grep -i mongo |grep -iv sec | awk {'print $1'})"
TIME_STAMP="$(date +'%Y%m%d')"
BACKUP_DIR=/var/mongobackup
USER_NAME="$(docker inspect $CONTAINER_NAME | grep -i MONGODB_USERNAME | cut -d "=" -f2 | cut -d "\"" -f1 )"
PASSWORD=$(docker inspect $CONTAINER_NAME | grep -i MONGODB_PASSWORD | cut -d "=" -f2 | cut -d "\"" -f1)
DB=$(docker inspect $CONTAINER_NAME | grep -i MONGODB_DATABASE | cut -d "=" -f2 | cut -d "\"" -f1)
CONTAINER_DIR=/bitnami

# Creating Backup Directory
if [ ! -d $BACKUP_DIR ]; then
	echo "Creating Backup Dir "
	mkdir -p $BACKUP_DIR
fi 

#Backup DataBase
echo "Backing up DataBase"
docker exec -t $CONTAINER_NAME mkdir -p $CONTAINER_DIR/$TIME_STAMP 
docker exec -t $CONTAINER_NAME mongodump --host 127.0.0.1 --port=27017 --username=$USER_NAME --password=$PASSWORD --authenticationDatabase=$DB --db=$DB --out=$CONTAINER_DIR/$TIME_STAMP

# Coping files from container 
docker cp $CONTAINER_NAME:$CONTAINER_DIR/$TIME_STAMP ./
docker exec -t $CONTAINER_NAME rm -rf $CONTAINER_DIR/$TIME_STAMP

#Archiving and removing backup dir
tar cvf $TIME_STAMP.tar $TIME_STAMP 
cp $TIME_STAMP.tar $BACKUPDIR 
rm -rf $TIME_STAMP.tar


#Check If Backup Created Successfully
if [ $? -eq 0 ]; then 
	echo "Backup Done successfully"
else
	echo "Something Went Wrong"
fi

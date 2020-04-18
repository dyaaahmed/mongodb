#!/bin/bash
#This script dump mongodb containers

# list of mongodb containers ids
CONTAINER_NAME="$(docker ps | grep -i mongo |grep -iv sec | awk '{print $(NF)}')"

#Looping on mutliple containers id
for i in $CONTAINER_NAME; do

#defining variables
TIME_STAMP="$(date +'%Y%m%d')"
BACKUP_DIR=/var/mongobackup/$i
USER_NAME="$(docker inspect $i | grep -i MONGODB_USERNAME | cut -d "=" -f2 | cut -d "\"" -f1 )"
PASSWORD=$(docker inspect $i | grep -i MONGODB_PASSWORD | cut -d "=" -f2 | cut -d "\"" -f1)
DB=$(docker inspect $i | grep -i MONGODB_DATABASE | cut -d "=" -f2 | cut -d "\"" -f1)
CONTAINER_DIR=/bitnami

# Creating Backup Directory
if [ ! -d $BACKUP_DIR ]; then
	echo "Creating Backup Dir "
	mkdir -p $BACKUP_DIR
fi 

#Backup DataBase
echo "Backing up DataBase"
docker exec -t $i mkdir -p $CONTAINER_DIR/$TIME_STAMP 
docker exec -t $i mongodump --host 127.0.0.1 --port=27017 --username=$USER_NAME --password=$PASSWORD --authenticationDatabase=$DB --db=$DB --out=$CONTAINER_DIR/$TIME_STAMP

# Coping files from container and removing backup from containers 
docker cp $i:$CONTAINER_DIR/$TIME_STAMP ./
docker exec -t $i rm -rf $CONTAINER_DIR/$TIME_STAMP

#Archiving and removing backup dir
tar cvf $TIME_STAMP.tar $TIME_STAMP
cp $TIME_STAMP.tar $BACKUP_DIR/$i-$TIME_STAMP.tar
rm -rf $TIME_STAMP*

#Check If Backup Created Successfully in each container
if [ $? -eq 0 ]; then 
	echo "$i Backup Done successfully"
else
	echo "$i Something Went Wrong"
fi

done


#!/bin/bash
#This script dump mongodb containers

# Defining vars 
CONTAINER_NAME="$(docker ps | grep -i mongo |grep -iv sec | awk {'print $1'})"
for i in $CONTAINER_NAME; do
TIME_STAMP="$(date +'%Y%m%d')"
BACKUP_DIR=/var/mongobackup
USER_NAME="$(docker inspect $i | grep -i MONGODB_USERNAME | cut -d "=" -f2 | cut -d "\"" -f1 )"
PASSWORD=$(docker inspect $i | grep -i MONGODB_PASSWORD | cut -d "=" -f2 | cut -d "\"" -f1)
DB=$(docker inspect $i | grep -i MONGODB_DATABASE | cut -d "=" -f2 | cut -d "\"" -f1)
CONTAINER_DIR=/bitnami

# Creating Backup Directory
if [ ! -d $BACKUP_DIR ]; then
	echo "Creating Backup Dir "
	mkdir -p $BACKUP_DIR
fi 

#Looping on multiple container
#Backup DataBase
echo "Backing up DataBase"
docker exec -t $i mkdir -p $CONTAINER_DIR/$TIME_STAMP 
docker exec -t $i mongodump --host 127.0.0.1 --port=27017 --username=$USER_NAME --password=$PASSWORD --authenticationDatabase=$DB --db=$DB --out=$CONTAINER_DIR/$TIME_STAMP

# Coping files from container 
docker cp $i:$CONTAINER_DIR/$TIME_STAMP ./
docker exec -t $i rm -rf $CONTAINER_DIR/$TIME_STAMP
#Archiving and removing backup dir
tar cvf $TIME_STAMP.tar $TIME_STAMP
cp $TIME_STAMP.tar $BACKUP_DIR/mongo-$TIME_STAMP-$i.tar
rm -rf $TIME_STAMP*

if [ $? -eq 0 ]; then 
	echo "Backup Done successfully"
else
	echo "Something Went Wrong"
fi
done
#Check If Backup Created Successfully


#!/bin/bash
#This script dump mongodb containers

# list of mongodb containers ids
CONTAINER_ID="$(docker ps | grep -i mongo | awk '{print $(NF)}')"

#Looping on mutliple containers id
for i in $CONTAINER_ID; do

#defining variables
TIME_STAMP="$(date +'%Y%m%d')"
USER_NAME="$(docker inspect $i | grep -i MONGODB_USERNAME | cut -d "=" -f2 | cut -d "\"" -f1 )"
PASSWORD=$(docker inspect $i | grep -i MONGODB_PASSWORD | cut -d "=" -f2 | cut -d "\"" -f1)
DB=$(docker inspect $i | grep -i MONGODB_DATABASE | cut -d "=" -f2 | cut -d "\"" -f1)
CONTAINER_DIR=/tmp
PARENT_BACKUP_DIR=/var/mongobackup

# Defining Backup Dir 
if [ "$1" == "daily" ]; then
BACKUP_DIR=$PARENT_BACKUP_DIR/daily
elif [ "$1" == "weekly" ]; then
BACKUP_DIR=$PARENT_BACKUP_DIR/weekly
elif [ "$1" == "monthly" ]; then
BACKUP_DIR=$PARENT_BACKUP_DIR/monthly
else
echo "please try agian with one of these values daily or weekly and monthly"
exit 0
fi

#Creating daily weekly monthly
for j in daily weekly monthly; do 
if [ ! -d $PARENT_BACKUP_DIR/$j/$i ]; then
        echo "Creating Backup Dir $BACKUP_DIR "
        mkdir -p $PARENT_BACKUP_DIR/$j/$i
fi
done

# Delete files older than 7 days
if [ "$1" == "daily" ]; then
find $PARENT_BACKUP_DIR/daily/ -type f -ctime +1 -name '*.tar' -execdir rm -- '{}' \;
# Delete files older than 4 weeks
elif [ "$1" == "weekly" ]; then
find $PARENT_BACKUP_DIR/weekly/ -type f -ctime +7 -name '*.tar' -execdir rm -- '{}' \;
# Delete files older than 3 months
elif [ "$1" == "monthly" ]; then
find $PARENT_BACKUP_DIR/monthly/ -type f -ctime +28 -name '*.tar' -execdir rm -- '{}' \;
fi

#Backup DataBase
echo "Backing up DataBase $i"
docker exec -t $i mkdir -p $CONTAINER_DIR/$TIME_STAMP 
docker exec -t $i mongodump --host 127.0.0.1 --port=27017 --username=$USER_NAME --password=$PASSWORD --authenticationDatabase=$DB --db=$DB --out=$CONTAINER_DIR/$TIME_STAMP

# Coping files from container and removing backup from containers 
docker cp $i:$CONTAINER_DIR/$TIME_STAMP /tmp
docker exec -t $i rm -rf $CONTAINER_DIR/$TIME_STAMP

#Archiving and removing backup dir
tar cvf /tmp/$TIME_STAMP.tar /tmp/$TIME_STAMP
cp /tmp/$TIME_STAMP.tar $BACKUP_DIR/$i/$i-$TIME_STAMP.tar
rm -rf /tmp/$TIME_STAMP*

#Check If Backup Created Successfully in each container
if [ $? -eq 0 ]; then 
	echo "$i Backup Done successfully"
else
	echo "Something Went Wrong in $i"
fi
done

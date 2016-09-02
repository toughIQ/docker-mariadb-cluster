#!/bin/bash

#!/bin/bash

DATE=`date "+%y%m%d%H%M"`

if [ -z "$BACKUP_DIR" ]; then
   BACKUP_DIR="/backup"
fi

if [ -z "$KEEP_DAYS" ]; then
   KEEP_DAYS=3
fi

echo "BACKUP nach $BACKUP_DIR"
echo "Current: full.sql"
mysqldump --user=$BACKUP_USER --password=$BACKUP_PASS --host=$BACKUP_HOST --all-databases --add-drop-table --add-drop-database --routines  |gzip > $BACKUP_DIR/full_$DATE.sql.gz

mysql --user=$BACKUP_USER --password=$BACKUP_PASS --host=$BACKUP_HOST -B -ss -e "show databases" | while read -r database
do
   #Skip not needed Databases
   if [ "$database" = "information_schema" ]; then
        continue
   fi
   if [ "$database" = "performance_schema" ]; then
        continue
   fi
   if [ "$database" = "ndbinfo" ]; then
        continue
   fi
   echo  "Current database: "$database
   mysqldump --user=$BACKUP_USER --password=$BACKUP_PASS --host=$BACKUP_HOST --add-drop-table --add-drop-database --database $database --tables --routines | gzip > $BACKUP_DIR/$database.database_$DATE.sql.gz
done


find $BACKUP_DIR -type f -ctime +$KEEP_DAYS  -exec rm {} \;

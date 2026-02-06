=========backup for prod=======
1st we create backup dir log dir

sudo mkdir -p /backup/cassandra/full
sudo mkdir -p /var/log/cassandra_backup/
sudo chown ec2-user:ec2-user /var/log/cassandra_backup/
sudo chown ec2-user:ec2-user /backup/cassandra/full/



vi full_backup.sh
=====
#!/bin/bash

# Variables
CASSANDRA_USER="cassandra"
DATE=$(date +%F)
SNAPSHOT_NAME="snapshot_$DATE"
DATA_DIR="/var/lib/cassandra/data"
BACKUP_DIR="/backup/cassandra/full/$DATE"
LOG_FILE="/var/log/cassandra_backup/full_backup.log"

mkdir -p $BACKUP_DIR

echo "[$(date)] Starting full snapshot backup" >> $LOG_FILE

# Take snapshot
nodetool snapshot -t $SNAPSHOT_NAME >> $LOG_FILE 2>&1

# Copy snapshot files
find $DATA_DIR -type d -name "$SNAPSHOT_NAME" | while read SNAP_DIR
do
  rsync -av $SNAP_DIR $BACKUP_DIR >> $LOG_FILE 2>&1
done

echo "[$(date)] Full snapshot backup completed" >> $LOG_FILE
====

chmod +x full_backup.sh 
ls
sudo mkdir -p /backup/cassandra/full
sudo mkdir -p /var/log/cassandra_backup/
./full_backup.sh 
sudo chown ec2-user:ec2-user /var/log/cassandra_backup/
sudo chown ec2-user:ec2-user /backup/cassandra/full/
./full_backup.sh 
ls /backup/cassandra/full/2026-02-06/snapshot_2026-02-06/

====incremental_backup

cat /opt/apache-cassandra-4.0.13/conf/cassandra.yaml | grep "incremental_backups:"
by defult it off we need to on
sed -i 's/^incremental_backups:.*/incremental_backups: true/' /opt/apache-cassandra-4.0.13/conf/cassandra.yaml
verify
grep "incremental_backups:" /opt/apache-cassandra-4.0.13/conf/cassandra.yaml

restart cluster one by one

sudo mkdir -p /backup/cassandra/incremental
sudo chown ec2-user:ec2-user /backup/cassandra/incremental/
📄 incremental_backup.sh
====

#!/bin/bash

INCR_DIR="/var/lib/cassandra/data"
BACKUP_DIR="/backup/cassandra/incremental"
LOG_FILE="/var/log/cassandra_backup/incremental_backup.log"

mkdir -p $BACKUP_DIR

echo "[$(date)] Starting incremental backup" >> $LOG_FILE

find $INCR_DIR -path "*backups*" -type f | while read FILE
do
  rsync -av $FILE $BACKUP_DIR >> $LOG_FILE 2>&1
done

echo "[$(date)] Incremental backup completed" >> $LOG_FILE
====

chmod +x incremental_backup.sh
./incremental_backup.sh


✅ 3️⃣ Cleanup Old Backups Script (Very Important)
📌 Purpose

Prevent disk full issues

Interviewers love this

📄 cleanup_old_backups.sh

#!/bin/bash

BACKUP_BASE="/backup/cassandra/full"
RETENTION_DAYS=14
LOG_FILE="/var/log/cassandra_backup/cleanup.log"

echo "[$(date)] Cleanup started" >> $LOG_FILE

find $BACKUP_BASE -type d -mtime +$RETENTION_DAYS -exec rm -rf {} \;

echo "[$(date)] Cleanup completed" >> $LOG_FILE


chmod +x cleanup_old_backups.sh
./cleanup_old_backups.sh



# Daily full snapshot at 1 AM
0 1 * * * cassandra /opt/backup/full_snapshot.sh

# Incremental backup every hour
0 * * * * cassandra /opt/backup/incremental_backup.sh

# Cleanup old backups
0 3 * * * cassandra /opt/backup/cleanup_old_backups.sh

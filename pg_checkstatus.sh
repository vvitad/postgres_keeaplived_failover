#!/usr/bin/env bash
export LANG=en_US.UTF-8
export PGPORT=5432
export PGUSER=postgres
export PGDBNAME=repltest
export PGDATA=/var/lib/postgresql/12/main


LOGFILE=/var/log/keepalived/keepalived_pg.log


SQL1='SELECT pg_is_in_recovery from pg_is_in_recovery();'
SQL2='update cluster_status set last_alive = now() where id = 1;'


DB_ROLE=`echo $SQL1  | psql -d $PGDBNAME -U $PGUSER -At -w`


if [[ $DB_ROLE == 't' ]]
then
    echo -e `date +"%F %T"` "`basename $0`: [INFO] PostgreSQL is running in STANDBY mode." >> $LOGFILE
        exit 0

elif [[ $DB_ROLE == 'f' ]]
then
    echo -e `date +"%F %T"` "`basename $0`: [INFO] PostgreSQL is running in PRIMARY mode." >> $LOGFILE
fi

# If current server is in STANDBY mode, then exit. Otherwise, update the cluster_status table. 

echo $SQL2 | psql -p $PGPORT -d $PGDBNAME -U $PGUSER -At -w
if [[ $? -ne 0 ]]
then
    echo -e `date +"%F %T"` "`basename $0`: [ERR] Cannot update 'cluster_status' table, is PostgreSQL running?" >> $LOGFILE
    exit 1
fi

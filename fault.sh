#!/usr/bin/env bash

export LANG=en_US.UTF-8
export PGPORT=5432
export PGUSER=postgres
export PG_OS_USER=postgres
export PGDBNAME=core
export PGHOME=/usr/lib/postgresql/12/
export PGDATA=/var/lib/postgresql/12/main


LOGFILE=/var/log/keepalived/keepalived_pg.log

echo -e "`date +%F\ %T`" "`basename $0`: [WARN] Keepalived failed, Checking if need to shutdown PostgreSQL... " >> $LOGFILE

SQL1="select pg_is_in_recovery from pg_is_in_recovery();"
DB_ROLE=`echo $SQL1 |$PGHOME/bin/psql -At -p $PGPORT -U $PGUSER -d $PGDBNAME -w`

# If the keepalived daemon on primary entering FAULT state, then shutdown the postgresql server.
# If the keepalived daemon on standby entering FAULT state, then do nothing.

if [[ $DB_ROLE == 'f' ]]; then
    echo -e "`date +%F\ %T`" "`basename $0`: [WARN] PostgreSQL is running in PRIMARY mode, shutting down... " >> $LOGFILE
    sudo su - $PG_OS_USER -c "/usr/lib/postgresql/12/bin/pg_ctl status -D /var/lib/postgresql/12/main'" &> /dev/null
    if [[ $? -eq 0 ]]; then
        echo -e "`date +%F\ %T`" "`basename $0`: [INFO] Shutdown PostgreSQL success." >> $LOGFILE
    else
        echo -e "`date +%F\ %T`" "`basename $0`: [ERR] Shutdown PostgreSQL failed, check logfile for details." >> $LOGFILE
    fi

elif [[ $DB_ROLE == 't' ]]; then
    echo -e "`date +%F\ %T`" "`basename $0`: [INFO] PostgreSQL is running in STANDBY mode, not recommended to shutdown." >> $LOGFILE
fi

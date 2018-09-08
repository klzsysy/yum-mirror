#!/usr/bin/env bash
# by klzsysy

set -xe

if which $1 > /dev/null ;then
    exec "$@"
    exit $?
fi 

DAYS_SYNC_TIME=${DAYS_SYNC_TIME:='01-10'}

WEEK_SYNC_TIME=${WEEK_SYNC_TIME:='all'}

if [ "${WEEK_SYNC_TIME}" == 'all' ];then
    WEEK_SYNC_TIME=$(seq 1 7)
fi

if [ -n "${HTTP_PORT}" ];then
    sed -i "s/8080/${HTTP_PORT}/" /etc/nginx/conf.d/nginx-site.conf
fi

function handle_TERM()
{
        kill -s SIGTERM $(ps aux | grep -v grep| grep  'nginx: master' | awk '{print $2}')
        kill -s SIGTERM "$syncpid"
        wait "$syncpid"
        exit
}

trap 'handle_TERM' SIGTERM

nginx -t && nginx

yumsync(){
    exec ./yum-mirror --tmppath=/data/cache yumfile --file config/yumfile.conf sync $@ &
    syncpid=$!
}

yumsync $@

while true;
do
    wait ${syncpid}
    if date '+%H-%M' | grep -Eq "${DAYS_SYNC_TIME}" && echo "${WEEK_SYNC_TIME}" | grep -q "$(date '+%u')" ;then
        yumsync $@
    else
        sleep 50 &
        wait $!
    fi
done

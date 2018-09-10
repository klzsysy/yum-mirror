#!/usr/bin/env bash
# by klzsysy

set -e

if [ "$#" -ne 0 ];then
    if which $1 > /dev/null ;then
        exec "$@"
        exit $?
    fi
fi

DAYS_SYNC_TIME=${DAYS_SYNC_TIME:='01-10'}

WEEK_SYNC_TIME=${WEEK_SYNC_TIME:='all'}
SERVER_NAME=${SERVER_NAME:-'localhost'}


if [ "${WEEK_SYNC_TIME}" == 'all' ];then
    WEEK_SYNC_TIME=$(seq 1 7)
fi

if [ -n "${HTTP_PORT}" ];then
    sed -i "s/8080/${HTTP_PORT}/" /etc/nginx/conf.d/nginx-site.conf
fi

function info(){
    echo "$(date '+%F %T') - info: $@"
}

function handle_TERM()
{
        kill -s SIGTERM $(ps aux | grep -v grep| grep  'nginx: master' | awk '{print $2}')
        kill -s SIGTERM "${sleep_pid}"
        kill -s SIGTERM "$syncpid"
        wait "$syncpid"
        exit $?
}

trap 'handle_TERM' SIGTERM


nginx -t && nginx


info "build client repo"
awk -f build_client_repo.awk config/yumfile.conf > /data/client.repo
info "you repo url: $(echo "${SERVER_NAME}" | sed 's/\$//')/client.repo"

yumsync(){
    info "start sync ....."
    exec ./yum-mirror ${OPTION} --tmppath=/data/cache yumfile --file config/yumfile.conf sync $@ &
    syncpid=$!
    wait $syncpid
    info "sync end"
}

yumsync $@

while true;
do
    if date '+%H-%M' | grep -Eq "${DAYS_SYNC_TIME}" && echo "${WEEK_SYNC_TIME}" | grep -q "$(date '+%u')" ;then
        yumsync $@
    else
        sleep 50 &
        sleep_pid=$!
        wait ${sleep_pid}
    fi
done

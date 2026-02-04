#!/bin/bash

# exit on any error
set -e

source /etc/profile > /dev/null

source dt-app-conf.sh

#CURR_DIR=$(dirname $(readlink -f $0))
LOG_DIR=/root/logs/bounce_containers
LOG_FILE=${LOG_DIR}/`date +%Y%m%d-%H%M%S`.log

if ! [ -d $LOG_DIR ]; then
	mkdir -p $LOG_DIR
fi

SILENT_OUTPUT=FALSE
for arg in "$@"; do
	case "$arg" in
		"-q")
			SILENT_OUTPUT=TRUE
			;;
		*)
			;;
	esac
done

if [ "$SILENT_OUTPUT" = "TRUE" ]; then
	exec 1>>${LOG_FILE}
else
	exec 1>&2
fi
exec 2> >(tee -a ${LOG_FILE} >&2)

function getYmlsParam {
	for yml in ${1}/docker-compose*.y*ml; do
		echo -n "-f $yml "
	done
}

for depl in \
$(echo $DTCONF_deployments | tr ',' ' ') \
; do
	(
	docker compose --ansi=never `getYmlsParam $depl` pull
	docker compose --ansi=never `getYmlsParam $depl` up -d
	) 2>&1
        # this redirection is wrong. but compose spills everything to stderr
done

echo
echo "Cleaning up dangling images and build cache.."
echo
# Don't want to use that because it also removes stopped containers
#docker system prune -f

#for img in $(docker images "docker.xicod.com/xicod/*" --filter "dangling=true" -q --no-trunc); do docker rmi $img; done
#for img in $(docker images --filter "dangling=true" -q --no-trunc); do docker rmi $img; done
docker image prune -f

# Don't use --all (-a) here. That will remove absolutely all cache, except
# currently running build processes. Without --all, it's only dangling cache
# objects, like expected.
docker builder prune -f

echo
echo '!! DONE RUN !!'
echo

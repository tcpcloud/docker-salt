#!/bin/bash -e

[[ "$DEBUG" =~ ^(True|true|1|yes)$ ]] && set -x

TAG_PREFIX=tcpcloud
BUILD_PATH=${*:-"salt-base.dockerfile services"}
SLEEP_TIME=${SLEEP_TIME:-3}
BUILD_ARGS=${BUILD_ARGS:-""}
MAX_JOBS=${JOBS:-1}

JOBS=0
RETVAL=0

build_image() {
    name=$(echo $(basename $1 .dockerfile) | sed 's,\.,-,g')
    echo "== Building $name"
    stdbuf -oL -eL docker build --no-cache --rm=true -t $TAG_PREFIX/$name $BUILD_ARGS -f $1 . 2>&1 | stdbuf -oL -eL tee log/${name}.log
}

[ ! -d log ] && mkdir log || rm -f log/*.log

build_image salt-base.dockerfile

find $BUILD_PATH -name "*.dockerfile" | while read service; do
    if [ "$service" == "salt-base.dockerfile" ]; then
        continue
    fi

    if [ $JOBS -ge $MAX_JOBS ]; then
        wait
        JOBS=0
    fi

    build_image $service &
    JOBS=$[ $JOBS + 1 ]
done

sleep 10
wait
echo

for log_file in log/*.log; do
    if [ ! -z $(grep "Successfully built " $log_file 2>/dev/null) ]; then
        echo "== Build of $(basename $log_file .log) failed" 1>&2
        RETVAL=1
    fi
done

exit $RETVAL

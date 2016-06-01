#!/bin/bash -e

TAG_PREFIX=tcpcloud
BUILD_PATH=${1:-"salt-base.dockerfile services"}
SLEEP_TIME=${SLEEP_TIME:-3}
MAX_JOBS=${JOBS:-1}

JOBS=0

build_image() {
    name=$(echo $(basename $1 .dockerfile) | sed 's,\.,-,g')
    echo "== Building $name"
    docker build --no-cache --rm=true -t $TAG_PREFIX/$name -f $1 .
}

find $BUILD_PATH -name "*.dockerfile" | while read service; do
    if [ "$service" == "salt-base.dockerfile" ]; then
        build_image $service
    else
        if [ $JOBS -ge $MAX_JOBS ]; then
            wait
            JOBS=0
        fi
        build_image $service &
        JOBS=$[ $JOBS + 1 ]
    fi
done

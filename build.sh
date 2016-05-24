#!/bin/bash -e

TAG_PREFIX=tcpcloud
BUILD_PATH=${1:-"salt-base.dockerfile services"}

build_image() {
    name=$(echo $(basename $1 .dockerfile) | sed 's,\.,-,g')
    echo "== Building $name"
    docker build --no-cache --rm=true -t $TAG_PREFIX/$name -f $1 .
}

find $BUILD_PATH -name "*.dockerfile" | while read service; do
    build_image $service
done

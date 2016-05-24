#!/bin/bash -e

TAG_PREFIX=tcpcloud

build_image() {
    name=$(echo $(basename $1 .dockerfile) | sed 's,\.,-,g')
    echo "== Building $name"
    docker build --no-cache --rm=true -t $TAG_PREFIX/$name -f $1 .
}

if [ -n $1 ]; then
    build_image $1
else
    build_image salt-base.dockerfile

    find services -name "*.dockerfile" | while read service; do
        build_image $service
    done
fi

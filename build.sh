#!/bin/bash -e

TAG_PREFIX=tcpcloud

build_image() {
    name=$(echo $(basename $1 .dockerfile) | sed 's,\.,-,g')
    echo "== Building $name"
    docker build --rm=true -t $TAG_PREFIX/$name -f $1 .
}

build_image salt-base.dockerfile

for service in services/*.dockerfile; do
    build_image $service
done

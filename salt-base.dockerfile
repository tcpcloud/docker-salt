FROM ubuntu:trusty

## Overridable parameters
ENV RECLASS_URL https://github.com/tcpcloud/workshop-salt-model.git
ENV RECLASS_BRANCH docker
ENV REPO_URL "http://apt.tcpcloud.eu/nightly/"
ENV REPO_COMPONENTS "main security extra tcp tcp-salt"

## Common
ENV DEBIAN_FRONTEND noninteractive
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/service

RUN apt-get update
RUN apt-get install -y wget

RUN echo "deb [arch=amd64] ${REPO_URL} trusty ${REPO_COMPONENTS}" > /etc/apt/sources.list
RUN wget -O - http://apt.tcpcloud.eu/public.gpg | apt-key add -
RUN apt-get update

RUN apt-get install -y salt-minion reclass git

## Salt
RUN apt-get install -y salt-formula-*
ADD files/minion.conf /etc/salt/minion
RUN test -d /etc/salt/minion.d || mkdir /etc/salt/minion.d

## Reclass
RUN test -d /etc/reclass || mkdir /etc/reclass
ADD files/reclass-config.yml /etc/reclass/reclass-config.yml

RUN git clone ${RECLASS_URL} /srv/salt/reclass -b ${RECLASS_BRANCH}
RUN ln -s /usr/share/salt-formulas/reclass/service /srv/salt/reclass/classes/service

# Workaround for master-less Salt with reclass
RUN reclass-salt --top > /usr/share/salt-formulas/env/top.sls

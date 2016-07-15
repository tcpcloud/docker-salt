FROM ubuntu:trusty

## Build parameters
ARG reclass_url=https://github.com/tcpcloud/workshop-salt-model.git
ARG reclass_branch=master
ARG reclass_key
ARG repo_branch=nightly

## Customizable parameters
ENV RECLASS_URL $reclass_url
ENV RECLASS_BRANCH $reclass_branch
ENV REPO_URL "http://apt.tcpcloud.eu/$repo_branch/"
ENV REPO_COMPONENTS "main security extra tcp tcp-salt"

## Common
ENV DEBIAN_FRONTEND noninteractive
ADD files/service /usr/sbin/service
RUN chmod +x /usr/sbin/service

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
RUN echo "noservices: True" > /etc/salt/grains

## Reclass
RUN test -n "${reclass_key}" && \
    (mkdir /root/.ssh; \
     echo -ne $(echo -ne ${reclass_key})|base64 -d > /root/.ssh/id_rsa; \
     chmod 600 /root/.ssh/id_rsa; \
     host=`echo "${RECLASS_URL}"|grep -Eo 'git@[a-z0-9\-\.]+:'|cut -d : -f 1|cut -d '@' -f 2`; \
     [ -n $host ] && ssh-keyscan $host >>/root/.ssh/known_hosts) || true
RUN test -d /etc/reclass || mkdir /etc/reclass
ADD files/reclass-config.yml /etc/reclass/reclass-config.yml

RUN git clone ${RECLASS_URL} /srv/salt/reclass -b ${RECLASS_BRANCH}
RUN ln -s /usr/share/salt-formulas/reclass/service /srv/salt/reclass/classes/service

# Workaround for master-less Salt with reclass
RUN reclass-salt --top > /usr/share/salt-formulas/env/top.sls

# Cleanup
RUN apt-get autoremove --purge -y
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/salt/* /root/.ssh

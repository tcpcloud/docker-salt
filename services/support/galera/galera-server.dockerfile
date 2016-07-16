# Copyright 2016 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM tcpcloud/salt-base

## Overridable parameters
ENV SERVICE mysql
ENV ROLE server

## Pillar
RUN mkdir -m700 /srv/salt/pillar
RUN echo "base:\n  ${SERVICE}-${ROLE}:\n    - ${SERVICE}-${ROLE}" > /srv/salt/pillar/top.sls
RUN reclass-salt --pillar ${SERVICE}-${ROLE} > /srv/salt/pillar/${SERVICE}-${ROLE}.sls

RUN rm -rf /srv/reclass /etc/reclass
ADD files/minion-pillar.conf /etc/salt/minion
RUN echo "id: ${SERVICE}-${ROLE}" >> /etc/salt/minion

# add our user and group first to make sure their IDs get assigned 
# consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql

ENV PERCONA_XTRADB_VERSION 5.6
ENV MYSQL_VERSION 5.6
ENV TERM linux

RUN apt-get update 
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y perl --no-install-recommends && rm -rf /var/lib/apt/lists/*

RUN apt-key adv --keyserver keys.gnupg.net --recv-keys 1C4CBDCDCD2EFD2A

RUN echo "deb http://repo.percona.com/apt trusty main" > /etc/apt/sources.list.d/percona.list
RUN echo "deb-src http://repo.percona.com/apt trusty main" >> /etc/apt/sources.list.d/percona.list

# the "/var/lib/mysql" stuff here is because the mysql-server
# postinst doesn't have an explicit way to disable the 
# mysql_install_db codepath besides having a database already
# "configured" (ie, stuff in /var/lib/mysql/mysql)
# also, we set debconf keys to make APT a little quieter
RUN { \
                echo percona-server-server-5.6 percona-server-server/data-dir select ''; \
                echo percona-server-server-5.6 percona-server-server/root_password password ''; \
        } | debconf-set-selections \
        && apt-get update && DEBIAN_FRONTEND=nointeractive apt-get install -y gettext-base percona-xtradb-cluster-client-"${MYSQL_VERSION}" \ 
           percona-xtradb-cluster-common-"${MYSQL_VERSION}" percona-xtradb-cluster-server-"${MYSQL_VERSION}" \
        && rm -rf /var/lib/apt/lists/* \
        && rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql 

VOLUME /var/lib/mysql

RUN salt-call --local --retcode-passthrough state.highstate

COPY services/support/galera/my.cnf /etc/mysql/my.cnf
COPY services/support/galera/cluster.cnf /etc/mysql/conf.d/cluster.cnf

COPY services/support/galera/docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 3306 4444 4567 4568
CMD ["mysqld"]

RUN rm -f /etc/salt/grains
RUN apt-get autoremove --purge -y
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/salt/*

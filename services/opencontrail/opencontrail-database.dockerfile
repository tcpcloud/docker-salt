FROM tcpcloud/salt-base

## Overridable parameters
ENV SERVICE opencontrail
ENV ROLE database

### XXX
RUN rm -rf /usr/share/salt-formulas/env/opencontrail
RUN git clone https://github.com/pupapaik/salt-formula-opencontrail.git opencontrail; mv opencontrail/opencontrail /usr/share/salt-formulas/env/
### XXX

## Pillar
RUN mkdir -m700 /srv/salt/pillar
RUN echo "base:\n  ${SERVICE}-${ROLE}:\n    - ${SERVICE}-${ROLE}" > /srv/salt/pillar/top.sls
RUN reclass-salt --pillar ${SERVICE}-${ROLE} > /srv/salt/pillar/${SERVICE}-${ROLE}.sls

RUN rm -rf /srv/reclass /etc/reclass
ADD files/minion-pillar.conf /etc/salt/minion
RUN echo "id: ${SERVICE}-${ROLE}" >> /etc/salt/minion

## Application
RUN salt-call --local --retcode-passthrough state.show_top | grep -- '- linux' 2>&1 >/dev/null && \
    salt-call --local --retcode-passthrough state.sls linux || true
RUN salt-call --local --retcode-passthrough state.highstate

# create zookeeper supervisor entry
RUN echo '[program:zookeeper]\n\
command = /usr/bin/java -cp /etc/zookeeper/conf:/usr/share/java/jline.jar:/usr/share/java/log4j-1.2.jar:/usr/share/java/xercesImpl.jar:/usr/share/java/xmlParserAPIs.jar:/usr/share/java/netty.jar:/usr/share/java/slf4j-api.jar:/usr/share/java/slf4j-log4j12.jar:/usr/share/java/zookeeper.jar -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.local.only=false -Dzookeeper.log.dir=/var/log/zookeeper -Dzookeeper.root.logger=INFO,CONSOLE,ROLLINGFILE org.apache.zookeeper.server.quorum.QuorumPeerMain /etc/zookeeper/conf/zoo.cfg\n\
stdout_logfile = /var/log/zookeeper/zookeeper.out\n\
stderr_logfile = /var/log/zookeeper/zookeeper.err\n\
autorestart = true\n\
stopasgroup=true'\
  > /etc/contrail/supervisord_database_files/zookeeper.ini

ENTRYPOINT /entrypoint.sh
EXPOSE 9160 2181

# Cleanup
RUN apt-get autoremove --purge -y
RUN apt-get clean
RUN rm -rf /etc/salt/grains /etc/salt/grains.d/* /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/salt/*
# Dirty hack to avoid running apt-get update during entrypoint's Salt run
RUN mv /usr/bin/apt-get /usr/bin/apt-get.orig && \
    echo "#!/bin/sh\nexit 0" > /usr/bin/apt-get && \
    chmod +x /usr/bin/apt-get

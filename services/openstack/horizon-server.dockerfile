FROM tcpcloud/salt-base

## Overridable parameters
ENV SERVICE horizon
ENV ROLE server

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

ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 80

# Cleanup
RUN apt-get autoremove --purge -y
RUN apt-get clean
RUN rm -rf /etc/salt/grains /etc/salt/grains.d/* /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/salt/*
# Dirty hack to avoid running apt-get update during entrypoint's Salt run
RUN mv /usr/bin/apt-get /usr/bin/apt-get.orig && \
    echo "#!/bin/sh\nexit 0" > /usr/bin/apt-get && \
    chmod +x /usr/bin/apt-get
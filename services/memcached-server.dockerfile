FROM tcpcloud/salt-base

## Overridable parameters
ENV SERVICE memcached
ENV ROLE server

## Pillar
RUN mkdir -m700 /srv/salt/pillar
RUN echo "base:\n  ${SERVICE}-${ROLE}:\n    - ${SERVICE}-${ROLE}" > /srv/salt/pillar/top.sls
RUN reclass-salt --pillar ${SERVICE}-${ROLE} > /srv/salt/pillar/${SERVICE}-${ROLE}.sls

RUN rm -rf /srv/reclass /etc/reclass
ADD files/minion-pillar.conf /etc/salt/minion
RUN echo "id: ${SERVICE}-${ROLE}" >> /etc/salt/minion

### XXX
RUN rm -rf /usr/share/salt-formulas/env/memcached
RUN git clone https://github.com/tcpcloud/salt-formula-memcached.git -b docker memcached; mv memcached/memcached /usr/share/salt-formulas/env/
### XXX

## Application
RUN salt-call --id=${SERVICE}-${ROLE} --local --retcode-passthrough state.show_top | grep -- '- linux' 2>&1 >/dev/null && \
    salt-call --id=${SERVICE}-${ROLE} --local --retcode-passthrough state.sls linux || true
RUN salt-call --id=${SERVICE}-${ROLE} --local --retcode-passthrough state.highstate

ENTRYPOINT /entrypoint.sh
EXPOSE 11211

## Cleanup
RUN rm -f /etc/salt/grains
RUN apt-get autoremove --purge -y
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/salt/*

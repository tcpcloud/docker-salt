FROM tcpcloud/salt-base

## Overridable parameters
ENV SERVICE keystone
ENV ROLE server

### XXX
RUN rm -rf /usr/share/salt-formulas/env/keystone
RUN git clone https://github.com/fpytloun/salt-formula-keystone.git -b docker keystone; mv keystone/keystone /usr/share/salt-formulas/env/
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

ENTRYPOINT /entrypoint.sh
EXPOSE 5000 35357

## Cleanup
RUN rm -f /etc/salt/grains
RUN apt-get autoremove --purge -y
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/salt/*

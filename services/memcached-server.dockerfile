FROM tcpcloud/salt-base

## Overridable parameters
ENV SERVICE memcached
ENV ROLE server

### XXX

RUN git clone https://github.com/tcpcloud/salt-formula-memcached.git -b docker memcached
RUN rm -rf /usr/share/salt-formulas/env/memcached
RUN mv memcached/memcached /usr/share/salt-formulas/env/

### XXX

## Application
RUN salt-call --id=${SERVICE}-${ROLE} --local --retcode-passthrough state.show_top
RUN salt-call --id=${SERVICE}-${ROLE} --local --retcode-passthrough state.show_top | grep -- '- linux' 2>&1 >/dev/null && \
    salt-call --id=${SERVICE}-${ROLE} --local --retcode-passthrough state.sls linux || true
RUN salt-call --id=${SERVICE}-${ROLE} --local --retcode-passthrough state.highstate

ENTRYPOINT /entrypoint.sh

## Cleanup
RUN apt-get purge -y salt-master salt-minion reclass git salt-formula-*
RUN apt-get autoremove --purge -y
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /srv/salt /etc/salt /etc/reclass /usr/share/salt-formulas

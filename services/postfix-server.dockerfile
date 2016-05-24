FROM tcpcloud/salt-base

## Overridable parameters
ENV SERVICE postfix
ENV ROLE server

## Application
RUN salt-call --id=${SERVICE}-${ROLE} --local --retcode-passthrough state.show_top
RUN salt-call --id=${SERVICE}-${ROLE} --local --retcode-passthrough state.show_top | grep -- '- linux' 2>&1 >/dev/null && \
    salt-call --id=${SERVICE}-${ROLE} --local --retcode-passthrough state.sls linux || true
RUN salt-call --id=${SERVICE}-${ROLE} --local --retcode-passthrough state.highstate

ADD files/postfix/entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT /entrypoint.sh

## Cleanup
RUN rm -f /etc/salt/grains || true
RUN apt-get purge -y salt-master salt-minion reclass git salt-formula-*
RUN apt-get autoremove --purge -y
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /srv/salt /etc/salt /etc/reclass /usr/share/salt-formulas

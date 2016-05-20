#!/bin/sh

sed -i s,postfix.server,$(hostname -f),g /etc/postfix/main.cf
sed -i s,\$POSTFIX_ORIGIN,$(hostname -d),g /etc/postfix/main.cf

/usr/sbin/postfix start

#!/bin/sh

sed -i s,postfix\.server,$(hostname -f) /etc/postfix/main.cf
sed -i s,\$POSTFIX_ORIGIN,$(hostname -d) /etc/postfix/main.cf

/usr/sbin/postfix start

#!/bin/sh

sed -i s,postfix.server,$(hostname -f),g /etc/postfix/main.cf
sed -i s,\$POSTFIX_ORIGIN,$(hostname -d),g /etc/postfix/main.cf

# call "postfix stop" when exiting
trap "{ echo Stopping postfix; /usr/sbin/postfix stop; exit 0; }" EXIT

# start postfix
/usr/sbin/postfix -c /etc/postfix start

# keep running
sleep infinity

#!/bin/sh
diff /etc/postfix/tls /tmp/tls || exit 2

[[ $(ps aux | grep '[r]unsvdir\|[p]ostfix/master -s\|[d]ovecot -F\|[p]ickup' | wc -l) -ge '4' ]]
exit $?
#!/bin/sh
diff /etc/postfix/tls /tmp/tls || exit 2

# in 3 days
openssl x509 -checkend $(( 24*3600*3 )) -noout -in /etc/postfix/tls/bundle.crt
if [ $? -ne 0 ]; then
  echo 'bad - certificate expires within 3 days'
  exit 3
fi

[[ $(ps aux | grep '[r]unsvdir\|[p]ostfix/master -s\|[d]ovecot -F\|[p]ickup' | wc -l) -ge '4' ]]
exit $?
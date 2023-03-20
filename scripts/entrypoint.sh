#!/bin/sh

cat <<EOF
################################################################################

Welcome to the ghcr.io/servercontainers/minimail

################################################################################

You'll find this container sourcecode here:

    https://github.com/ServerContainers/minimail

The container repository will be updated regularly.

################################################################################


EOF

cat /container/config/postfix/main-*.conf > /etc/postfix/main.cf
cat /container/config/postfix/master.conf > /etc/postfix/master.cf
cat /container/config/dovecot/dovecot.conf > /etc/dovecot/dovecot.conf
/container/scripts/add-mail-accounts.sh

##
# POSTFIX MYNETWORKS
##

AVAILABLE_NETWORKS="127.0.0.0/8"
if [ ! -z ${AUTO_TRUST_NETWORKS+x} ]; then
  AVAILABLE_NETWORKS=$(/container/scripts/list-available-networks.sh | tr '\n' ',' | sed 's/,$//g')
  echo ">> trust all available networks: $AVAILABLE_NETWORKS"
fi

postconf -e "mynetworks=$AVAILABLE_NETWORKS"

if [ ! -z ${ADDITIONAL_MYNETWORKS+x} ]; then
  echo ">> update mynetworks to: $AVAILABLE_NETWORKS,$ADDITIONAL_MYNETWORKS"
  postconf -e "mynetworks = $AVAILABLE_NETWORKS,$ADDITIONAL_MYNETWORKS"
fi

if [ ! -z ${MYNETWORKS+x} ]; then
  if [ ! -z ${ADDITIONAL_MYNETWORKS+x} ]; then
    echo ">> Warning ADDITIONAL_MYNETWORKS will be ignored! only $MYNETWORKS will be set!"
  fi
  echo ">> update mynetworks to: $MYNETWORKS"
  postconf -e "mynetworks = $MYNETWORKS"
fi

##
# POSTFIX GENERAL
##

  if [ -z ${RELAYHOST+x} ]; then
    echo ">> it is advised to use this container with a relayhost (maybe use servercontainers/mail-gateway)..."
  else
    echo ">> setting relayhost to: $RELAYHOST"
    postconf -e "relayhost = $RELAYHOST"
  fi

  if [ -z ${MAIL_FQDN+x} ]; then
    MAIL_FQDN="mailbox.local"
  fi

  if echo "$MAIL_FQDN" | grep -v '\.'; then
    MAIL_FQDN="$MAIL_FQDN.local"
  fi
  MAIL_FQDN=$(echo "$MAIL_FQDN" | sed 's/[^.0-9a-z\-]//g')

  MAIL_NAME=$(echo "$MAIL_FQDN" | cut -d'.' -f1)
  MAILDOMAIN=$(echo "$MAIL_FQDN" | cut -d'.' -f2-)

  echo ">> set mail host to: $MAIL_FQDN"
  echo "$MAIL_FQDN" > /etc/mailname
  echo "$MAIL_NAME" > /etc/hostname
  postconf -e "myhostname = $MAIL_FQDN"

  [ -z ${POSTFIX_SMTPD_BANNER+x} ] && POSTFIX_SMTPD_BANNER="$MAIL_FQDN ESMTP"
  echo ">> POSTFIX set smtpd_banner = $POSTFIX_SMTPD_BANNER"
  postconf -e "smtpd_banner = $POSTFIX_SMTPD_BANNER"


  if [ ! -z ${POSTFIX_QUEUE_LIFETIME_BOUNCE+x} ]; then
    echo ">> POSTFIX set bounce_queue_lifetime = $POSTFIX_QUEUE_LIFETIME_BOUNCE"
    postconf -e "bounce_queue_lifetime = $POSTFIX_QUEUE_LIFETIME_BOUNCE"
  fi

  if [ ! -z ${POSTFIX_QUEUE_LIFETIME_MAX+x} ]; then
    echo ">> POSTFIX set maximal_queue_lifetime = $POSTFIX_QUEUE_LIFETIME_MAX"
    postconf -e "maximal_queue_lifetime = $POSTFIX_QUEUE_LIFETIME_MAX"
  fi

  if [ ! -z ${POSTFIX_MYDESTINATION+x} ]; then
    echo ">> POSTFIX set mydestination = $POSTFIX_MYDESTINATION"
    postconf -e "mydestination = $POSTFIX_MYDESTINATION"
  fi

  if [ -f /etc/postfix/additional/transport ]; then
    echo ">> POSTFIX found 'additional/transport' activating it as transport_maps"
    postconf -e "transport_maps = texthash:/etc/postfix/additional/transport"
  fi

  if [ -f /etc/postfix/additional/header_checks ]; then
    echo ">> POSTFIX found 'additional/header_checks' activating it as header_checks"
    postconf -e "header_checks = regexp:/etc/postfix/additional/header_checks"
  fi

##
# SSL Stuff
##

/container/scripts/add-mail-ssl.sh

##
# TLS Cert Renew Stuff
##

rm -rf /tmp/tls 2> /dev/null
cp -a /etc/postfix/tls /tmp/tls

##
# CONTAINER GENERAL
##

echo ">> fix file permissions"
chown -R dockervmail:dockervmail /var/vmail
chgrp postdrop /etc/dovecot/dovecot.conf
chmod g+r /etc/dovecot/dovecot.conf
chown -R root:root /etc/postfix/tls 2>/dev/null >/dev/null
chmod 555 /etc/postfix/tls 2>/dev/null >/dev/null
chmod -R 644 /etc/postfix/tls/* 2>/dev/null >/dev/null

##
# CMD
##
echo ">> CMD: exec docker CMD"
echo "$@"
exec "$@"
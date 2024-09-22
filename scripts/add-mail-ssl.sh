#!/bin/sh
cat <<EOF >> /etc/postfix/main.cf

#########################
##### TLS settings ######
#########################

EOF


  if [ -z ${POSTFIX_SSL_OUT_CERT+x} ]; then
    POSTFIX_SSL_OUT_CERT="/etc/postfix/tls/client.crt"
  fi

  if [ -z ${POSTFIX_SSL_OUT_KEY+x} ]; then
    POSTFIX_SSL_OUT_KEY="/etc/postfix/tls/client.key"
  fi

  if [ -z ${POSTFIX_SSL_OUT_SECURITY_LEVEL+x} ]; then
    POSTFIX_SSL_OUT_SECURITY_LEVEL="may"
  fi

  if [[ -f "$POSTFIX_SSL_OUT_CERT" && -f "$POSTFIX_SSL_OUT_KEY" ]]; then
    echo ">> POSTFIX SSL - enabling outgoing SSL"
cat <<EOF >> /etc/postfix/main.cf

### outgoing connections ###
# smtp_tls_security_level = encrypt # for secure connections only
smtp_tls_security_level = $POSTFIX_SSL_OUT_SECURITY_LEVEL
smtp_tls_cert_file = $POSTFIX_SSL_OUT_CERT
smtp_tls_key_file = $POSTFIX_SSL_OUT_KEY
smtp_tls_exclude_ciphers = aNULL, DES, RC4, MD5, 3DES
smtp_tls_mandatory_exclude_ciphers = aNULL, DES, RC4, MD5, 3DES
smtp_tls_protocols = !SSLv3
smtp_tls_mandatory_protocols = !SSLv3
smtp_tls_mandatory_ciphers = high
smtp_tls_loglevel = 1

EOF
  fi

  if [ -z ${POSTFIX_SSL_IN_CERT+x} ]; then
    POSTFIX_SSL_IN_CERT="/etc/postfix/tls/bundle.crt"
  fi

  if [ -z ${POSTFIX_SSL_IN_KEY+x} ]; then
    POSTFIX_SSL_IN_KEY="/etc/postfix/tls/cert.key"
  fi

  if [ -z ${POSTFIX_SSL_IN_SECURITY_LEVEL+x} ]; then
    POSTFIX_SSL_IN_SECURITY_LEVEL="may"
  fi

  if [[ ! -f "$POSTFIX_SSL_IN_CERT" || ! -f "$POSTFIX_SSL_IN_KEY" ]]; then
    echo ">> POSTFIX SSL - generating incoming self signed ssl cert"
    openssl req -new -x509 -days 3650 -nodes \
      -newkey rsa:4096 \
      -subj "/C=XX/ST=XXXX/L=XXXX/O=XXXX/CN=$MAIL_FQDN" \
      -out "$POSTFIX_SSL_IN_CERT" \
      -keyout "$POSTFIX_SSL_IN_KEY" \
      -sha256
  fi

  if [[ -f "$POSTFIX_SSL_IN_CERT" && -f "$POSTFIX_SSL_IN_KEY" ]]; then
    echo ">> POSTFIX SSL - enabling incoming SSL"
cat <<EOF >> /etc/postfix/main.cf

### incoming connections ###

# smtpd_tls_security_level = encrypt # for secure connections only
smtpd_tls_security_level = $POSTFIX_SSL_IN_SECURITY_LEVEL
smtpd_tls_cert_file = $POSTFIX_SSL_IN_CERT
smtpd_tls_key_file = $POSTFIX_SSL_IN_KEY
smtpd_tls_exclude_ciphers = aNULL, DES, RC4, MD5, 3DES
smtpd_tls_mandatory_exclude_ciphers = aNULL, DES, RC4, MD5, 3DES
smtpd_tls_protocols = !SSLv3
smtpd_tls_mandatory_protocols = !SSLv3
smtpd_tls_mandatory_ciphers = high
smtpd_tls_loglevel = 1

EOF
  fi

  if [ -f /etc/postfix/tls/rootCA.crt ]; then
    echo ">> POSTFIX SSL - enabling CA based Client Authentication"
    postconf -e "smtpd_tls_ask_ccert = yes"
    postconf -e "smtpd_tls_CAfile = /etc/postfix/tls/rootCA.crt"
    postconf -e "smtpd_recipient_restrictions = permit_mynetworks permit_sasl_authenticated permit_tls_all_clientcerts reject_unauth_destination"
  fi

  if [ -f /etc/postfix/tls/dh4096.pem ]; then
    echo ">> using dh4096.pem provided in volume"
  else
    cp /etc/postfix/dh4096.pem /etc/postfix/tls/dh4096.pem
  fi

  if [ -f /etc/postfix/tls/dh2048.pem ]; then
    echo ">> using dh2048.pem provided in volume"
  else
    cp /etc/postfix/dh2048.pem /etc/postfix/tls/dh2048.pem
  fi  

  if [ -f /etc/postfix/tls/dh1024.pem ]; then
    echo ">> using dh1024.pem provided in volume"
  else
    cp /etc/postfix/dh1024.pem /etc/postfix/tls/dh1024.pem
  fi

  if [ -f /etc/postfix/tls/dh512.pem ]; then
    echo ">> using dh512.pem provided in volume"
  else
    cp /etc/postfix/dh512.pem /etc/postfix/tls/dh512.pem
  fi

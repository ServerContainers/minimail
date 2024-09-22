FROM alpine
# alpine:3.12

ENV PATH="/container/scripts:${PATH}"

RUN apk add --no-cache \
    runit \
  \
    postfix \
    dovecot \
    dovecot-lmtpd \
  \
 && mkdir /etc/postfix/tls /var/vmail /container \
  \
 && openssl dhparam -out /etc/postfix/dh4096.pem 4096 \
 && openssl dhparam -out /etc/postfix/dh2048.pem 2048 \
 && openssl dhparam -out /etc/postfix/dh1024.pem 1024 \
 && openssl dhparam -out /etc/postfix/dh512.pem 512 \
  \
 && addgroup --gid 5000 dockervmail \
 && adduser --ingroup dockervmail --uid 5000 --home /var/vmail --shell /bin/false --disabled-password --gecos "" dockervmail

# postfix (smtp, submission)
EXPOSE 25 587

# dovecot (imap, imaps)
EXPOSE 143 993

VOLUME ["/etc/postfix/tls", "/etc/postfix/additional", "/var/vmail"]

COPY . /container/
HEALTHCHECK CMD ["/container/scripts/docker-healthcheck.sh"]
ENTRYPOINT ["/container/scripts/entrypoint.sh"]

CMD [ "runsvdir","-P", "/container/config/runit" ]

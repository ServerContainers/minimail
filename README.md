# Minimalistic Docker Mail Box (smtp + imap) Postfix/Dovecot (servercontainers/minimail) [x86 + arm]
_maintained by ServerContainers_

## What is it

This Dockerfile (available as ___servercontainers/minimail___) gives you a dovecot and postfix installation is meant to store mails, handle authentication and users and a new version (completely rewritten) of [ServerContainers/mail-box](https://github.com/ServerContainers/mail-box).

What makes it better?

- Alpine Linux Base (smaller footprint)
- Configure Users and Emails using Environment Variables
- Internaly only plain textfiles (`texthash`) are used (passdb, virtual stuff etc.)
- Just 3 Daemons - runit and postfix + dovecot
- Blowfish Crypt Password Hashing (bcrypt) available (`doveadm pw -s BLF-CRYPT` or `docker run --rm -ti alpine sh -c 'apk add dovecot; doveadm pw -s BLF-CRYPT'`)

It's based on the [_/alpine](https://registry.hub.docker.com/_/alpine/) Image (3.12)

View in Docker Registry [servercontainers/minimail](https://registry.hub.docker.com/u/servercontainers/minimail/)

View in GitHub [ServerContainers/minimail](https://github.com/ServerContainers/minimail)


## Changelogs
* 2021-07-28
    * healthcheck will fail if certificate is 3 days or less valid or already expired
* 2021-06-04
    * added healthcheck (will fail when certs are updated without container restart)
* 2021-05-25
    * removed tls session cache
* 2021-03-21
    * update and missing `hash:` support fix -> now `texthash` without `postmap`

## Environment variables

__OFFICIAL DATABASE MANAGMENT ENVIRONMENT VARIABLES__

_this on is needed to create a user/email, add a password hash to it and configure it's aliases_

- ACONF_USER_ACCOUNT_NAME_[...]
    - `[...]` must be replaced with an id to connect all the envs for one account together
    - the email address is specified in the value. e.g.: `test@mail.tld`

- ACONF_USER_PASSWORD_HASH_[...]
    - `[...]` must be replaced with an id to connect all the envs for one account together
    - the password hash is specified in the value. e.g.: `{BLF-CRYPT}$2y$05$4KFe0ntflWQ...`
    - Note: for a docker compose file you need to replace each `$` with a `$$` (then it's escaped and works)

- ACONF_USER_ALIASES_[...]
    - `[...]` must be replaced with an id to connect all the envs for one account together
    - the aliases for this users email are specified (use a blank to seperate multiplte) in the value. e.g.: `postmaster@mail.tld admin@mail.tld info@mail.tld`

_the main postmaster address will be the first address containing `postmaster` or the first address specified_ 

__OFFICIAL MAIL ENVIRONMENT VARIABLES__

- MAIL_FQDN
    - specify the mailserver name - only add FQDN not a hostname!
    - e.g. _my.mailserver.example.com_

- POSTFIX_SMTPD_BANNER
    - alter the SMTPD Banner of postfix e.g. _mailserver.example.local ESMTP_

- POSTFIX_MYDESTINATION
    - specify the domains which this mail-box handles

- AUTO_TRUST_NETWORKS
    - add all networks this container is connected to and trust them to send mails
    - _set to any value to enable_
- ADDITIONAL_MYNETWORKS
    - add this specific network to the automatically trusted onces
- MYNETWORKS
    - ignore all auto configured _mynetworks_ and replace them with this value
    - _overwrites networks specified in ADDITIONAL_MYNETWORKS_

- RELAYHOST
    - sets postfix relayhost - please take a look at the official documentation
    - _The form enclosed with [] eliminates DNS MX lookups. Don't worry if you don't know what that means. Just be sure to specify the [] around the mailhub hostname that your ISP gave to you, otherwise mail may be mis-delivered._

- POSTFIX_SSL_OUT_CERT
    - path to SSL Client certificate (outgoing connections)
    - default: _/etc/postfix/tls/client.crt_
- POSTFIX_SSL_OUT_KEY
    - path to SSL Client key (outgoing connections)
    - default: _/etc/postfix/tls/client.key_
- POSTFIX_SSL_OUT_SECURITY_LEVEL
    - SSL security level for outgoing connections
    - default: _may_

- POSTFIX_SSL_IN_CERT
    - path to SSL Cert/Bundle (incoming connections)
    - default: _/etc/postfix/tls/bundle.crt_
- POSTFIX_SSL_IN_KEY
    - path to SSL Cert key (incoming connections)
    - default: _/etc/postfix/tls/cert.key_
- POSTFIX_SSL_IN_SECURITY_LEVEL
    - SSL security level for incoming connections
    - default: _may_

- POSTFIX_QUEUE_LIFETIME_BOUNCE
    - The  maximal  time  a  BOUNCE MESSAGE is queued before it is considered undeliverable
    - By default, this is the same as the queue life time for regular mail
- POSTFIX_QUEUE_LIFETIME_MAX
    - maximum lifetime of regular (non bounce) messages

## Volumes

- /etc/postfix/tls
    - this is where the container looks for:
        - dh1024.pem (to overwrite the one generated at container build)
        - dh512.pem (to overwrite the one generated at container build)
        - rootCA.crt (to check valid client certificates against)
        - client.crt (outgoing SSL Client cert)
        - client.key (outgoing SSL Client key)
        - bundle.crt (incoming SSL Server cert/bundle)
        - cert.key (incoming SSL Server key)
- /etc/postfix/additional
    - this is where the container looks for:
        - transport (postfix transport text-file (`texthash`) - without been postmaped)
        - header_checks (postfix header_checks regex file)

#!/bin/bash
export IMG=$(docker build -q --pull --no-cache -t 'get-version' .)

export POSTFIX_VERSION=$(docker run --rm -t get-version apk list 2>/dev/null | grep '\[installed\]' | grep "postfix-[0-9]" | cut -d " " -f1 | sed 's/postfix-//g' | tr -d '\r')
export DOVECOT_VERSION=$(docker run --rm -t get-version apk list 2>/dev/null | grep '\[installed\]' | grep "dovecot-[0-9]" | cut -d " " -f1 | sed 's/dovecot-//g' | tr -d '\r')
export ALPINE_VERSION=$(docker run --rm -t get-version cat /etc/alpine-release | tail -n1 | tr -d '\r')
[ -z "$ALPINE_VERSION" ] && exit 1

export IMGTAG=$(echo "$1a$ALPINE_VERSION-p$POSTFIX_VERSION-d$DOVECOT_VERSION")
export IMAGE_EXISTS=$(docker pull "$IMGTAG" 2>/dev/null >/dev/null; echo $?)

# return latest, if container is already available :)
if [ "$IMAGE_EXISTS" -eq 0 ]; then
  echo "$1""latest"
else
  echo "$IMGTAG"
fi
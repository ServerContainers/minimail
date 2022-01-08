#!/bin/sh -x

IMG="servercontainers/minimail"

PLATFORM="linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6"

if [ -z ${POSTFIX_VERSION+x} ] || [ -z ${POSTFIX_VERSION+x} ] || [ -z ${POSTFIX_VERSION+x} ]; then
  docker-compose build -q --pull --no-cache
  export POSTFIX_VERSION=$(docker run --rm -ti "$IMG" apk list 2>/dev/null | grep '\[installed\]' | grep "postfix-[0-9]" | cut -d " " -f1 | sed 's/postfix-//g' | tr -d '\r')
  export DOVECOT_VERSION=$(docker run --rm -ti "$IMG" apk list 2>/dev/null | grep '\[installed\]' | grep "dovecot-[0-9]" | cut -d " " -f1 | sed 's/dovecot-//g' | tr -d '\r')
  export ALPINE_VERSION=$(docker run --rm -ti "$IMG" cat /etc/alpine-release | tail -n1 | tr -d '\r')
fi

echo "check if image was already build and pushed"
docker pull "$IMG:a$ALPINE_VERSION-p$POSTFIX_VERSION-d$DOVECOT_VERSION" 2>/dev/null >/dev/null && echo "image already build" && exit 1

docker buildx build -q --pull --no-cache --platform "$PLATFORM" -t "$IMG:a$ALPINE_VERSION-p$POSTFIX_VERSION-d$DOVECOT_VERSION" --push .

echo "$@" | grep "release" 2>/dev/null >/dev/null && echo ">> releasing new latest" && docker buildx build -q --pull --platform "$PLATFORM" -t "$IMG:latest" --push .
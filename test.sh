#!/bin/sh
# automated smoke test for the minimail container
# builds the image, starts it standalone and asserts postfix + dovecot come up
set -eu

IMAGE=minimail-test
NAME=minimail-test-run

FAILED=0
fail() {
  echo "FAIL: $*" >&2
  FAILED=1
}

cleanup() {
  echo ">> cleanup: removing container $NAME"
  docker rm -f "$NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

# grab the first line a tcp service sends, retrying while it spins up
# usage: grab_banner <port>
grab_banner() {
  _port="$1"
  _n=0
  while [ "$_n" -lt 15 ]; do
    _line=$(docker exec "$NAME" sh -c "nc -w 3 127.0.0.1 $_port </dev/null | head -n1" 2>/dev/null || true)
    if [ -n "$_line" ]; then
      echo "$_line"
      return 0
    fi
    _n=$((_n + 1))
    sleep 1
  done
  return 1
}

echo ">> building image $IMAGE"
docker build -t "$IMAGE" .

echo ">> (re)starting container $NAME"
docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME" \
  -e MAIL_FQDN=mailbox.example.com \
  -e ACONF_USER_ACCOUNT_NAME_tester='tester@mailbox.example.com' \
  -e ACONF_USER_PASSWORD_HASH_tester='{PLAIN}secret' \
  "$IMAGE"

echo ">> waiting for services to start (up to ~60s)"
READY=0
i=0
while [ "$i" -lt 30 ]; do
  if ! docker ps --format '{{.Names}}' | grep -q "^${NAME}$"; then
    echo "!! container is not running anymore, dumping logs:" >&2
    docker logs "$NAME" >&2 2>&1 || true
    fail "container exited during startup"
    break
  fi
  if docker exec "$NAME" ps aux 2>/dev/null | grep -q '[p]ostfix/master' \
     && docker exec "$NAME" ps aux 2>/dev/null | grep -qE '[d]ovecot -F'; then
    READY=1
    break
  fi
  i=$((i + 1))
  sleep 2
done

if [ "$READY" -ne 1 ] && [ "$FAILED" -eq 0 ]; then
  echo "!! services did not come up in time, dumping logs:" >&2
  docker logs "$NAME" >&2 2>&1 || true
  fail "timed out waiting for postfix/dovecot"
fi

# only run the deeper assertions if the container is still up
if docker ps --format '{{.Names}}' | grep -q "^${NAME}$"; then

  echo ">> assert: container is running"
  docker ps --format '{{.Names}}' | grep -q "^${NAME}$" \
    && echo "ok - container running" || fail "container not running"

  echo ">> assert: postfix/master process present"
  if docker exec "$NAME" ps aux | grep -q '[p]ostfix/master'; then
    echo "ok - postfix/master running"
  else
    fail "postfix/master process not found"
  fi

  echo ">> assert: dovecot process present"
  if docker exec "$NAME" ps aux | grep -qE '[d]ovecot -F'; then
    echo "ok - dovecot running"
  else
    fail "dovecot process not found"
  fi

  echo ">> assert: postfix check exits 0"
  if docker exec "$NAME" postfix check; then
    echo "ok - postfix check passed"
  else
    fail "postfix check returned non-zero"
  fi

  echo ">> assert: doveconf -n has no Fatal/Error"
  DOVECONF=$(docker exec "$NAME" doveconf -n 2>&1 || true)
  if echo "$DOVECONF" | grep -E 'Fatal|Error'; then
    fail "doveconf -n reported Fatal/Error"
  else
    echo "ok - doveconf -n clean"
  fi

  echo ">> assert: SMTP on port 25 returns 220 banner"
  SMTP_BANNER=$(grab_banner 25 || true)
  if echo "$SMTP_BANNER" | grep -q '^220'; then
    echo "ok - SMTP banner: $SMTP_BANNER"
  else
    fail "SMTP did not return a 220 banner (got: '$SMTP_BANNER')"
  fi

  echo ">> assert: IMAP on port 143 returns * OK greeting"
  IMAP_GREETING=$(grab_banner 143 || true)
  if echo "$IMAP_GREETING" | grep -q '^\* OK'; then
    echo "ok - IMAP greeting: $IMAP_GREETING"
  else
    fail "IMAP did not return a '* OK' greeting (got: '$IMAP_GREETING')"
  fi

fi

echo
if [ "$FAILED" -eq 0 ]; then
  echo "ALL TESTS PASSED"
  exit 0
else
  echo "SOME TESTS FAILED"
  exit 1
fi

#!/bin/sh

echo ">> clean user / email / domain config"
> /etc/dovecot/users
> /etc/postfix/vmailbox
> /etc/postfix/virtual
rm /aea 2>/dev/null

sed -i '/postmaster_address/d' /etc/dovecot/dovecot.conf

env | grep '^ACONF_USER_ACCOUNT_NAME_' | while read I_CONF
do
  NAME=$(echo "$I_CONF" | cut -d'=' -f1 | sed 's/ACONF_USER_ACCOUNT_NAME_//g')
  VALUE=$(echo "$I_CONF" | sed 's/^[^=]*=//g')

  EMAIL="$VALUE"
  echo "$EMAIL" >> /aea

  # create using `doveadm pw -s BLF-CRYPT -p "$PASSWORD"}//g'`
  PASSWORD_HASH=$(env | grep '^ACONF_USER_PASSWORD_HASH_'"$NAME" | sed 's/^[^=]*=//g')

  ALIASES=$(env | grep '^ACONF_USER_ALIASES_'"$NAME" | sed 's/^[^=]*=//g')

  echo ">> add user $NAME ($EMAIL)"
  echo "$EMAIL:$PASSWORD_HASH" >> /etc/dovecot/users
  echo "$EMAIL whatever" >> /etc/postfix/vmailbox
  postmap /etc/postfix/vmailbox

  echo ">> adding aliases for user $NAME ($EMAIL):"
  for ALIAS in $ALIASES;
  do
    echo "  >> adding alias $ALIAS"
    echo "$ALIAS" >> /aea
    echo "$ALIAS $EMAIL" >> /etc/postfix/virtual
    postmap /etc/postfix/virtual
  done
done

ALL_EMAIL_ADDRESSES=$(cat /aea | tr '\n' ' ')
rm /aea

POSTMASTER_ADDRESS=$(echo "$ALL_EMAIL_ADDRESSES" | tr ' ' '\n' | head -n1)
echo "$ALL_EMAIL_ADDRESSES" | tr ' ' '\n' | grep postmaster 2>/dev/null >/dev/null && POSTMASTER_ADDRESS=$(echo "$ALL_EMAIL_ADDRESSES" | tr ' ' '\n' | grep postmaster | head -n1)
echo ">> setting postmaster address to $POSTMASTER_ADDRESS"
echo "postmaster_address = $POSTMASTER_ADDRESS" >> /etc/dovecot/dovecot.conf

ALL_EMAIL_DOMAINS=$(echo "$ALL_EMAIL_ADDRESSES" | tr ' ' '\n' | sed 's/^.*@//g' | sort | uniq | tr '\n' ' ')
echo ">> adding domains $ALL_EMAIL_DOMAINS"
postconf -e "virtual_mailbox_domains=$ALL_EMAIL_DOMAINS"

echo ">> configured for the following email addresses:"
echo
echo "$ALL_EMAIL_ADDRESSES" | tr ' ' '\n'


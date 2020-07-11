#!/bin/sh

IFS=$'\n'       # make newlines the only separator
for j in $(ifconfig | grep inet | tr ' ' '\n' | grep 'Mask\|add' | tr '\n' ' ' | sed 's/addr/\naddr/g' | grep . | sed 's/[^0-9. ]//g')
do
  ADDR=$(echo "$j" | cut -d' ' -f1)
  MASK=$(echo "$j" | cut -d' ' -f2)

  NETWORK=$(ipcalc -n $ADDR $MASK | sed 's/^.*=//g')
  CIDR=$(ipcalc -p $ADDR $MASK | sed 's/^.*=//g')

  echo "$NETWORK/$CIDR"
done

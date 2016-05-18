#!/bin/bash

csv_input=$1

while IFS=, read dns_dame ip mask gw; do
  ./idrac.sh $dns_dame getniccfg
  ./idrac.sh $dns_dame setniccfg -s $ip $mask $gw
done < $csv_input
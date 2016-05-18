#!/bin/bash

csv_input=$1

while IFS=, read IP dns; do
    ./idrac.sh $IP set iDRAC.Nic.DNSRacName $dns
     echo "$dns hostname set"
done < $csv_input

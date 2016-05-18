#!/bin/bash

csv_input=$1

while IFS=, read IP dns; do
   mac=`./idrac.sh $dns racdump | egrep '^NIC.Integrated'`
   echo "$mac" | while read line; do
   	echo "$dns $line"
   done
done < $csv_input




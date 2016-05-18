#!/bin/bash

csv_input=$1

while IFS=, read dns_name ip mask gw; do
  ./idrac.sh $dns_name set iDRAC.SSH.Timeout 300
  ./idrac.sh $dns_name set iDRAC.Tuning.DefaultCredentialWarning Disabled
done < $csv_input

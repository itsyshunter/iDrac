#!/bin/bash

host_list=$1


while IFS=, read IP; do
     fping $IP
done < $host_list



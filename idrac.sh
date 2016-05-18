#!/bin/bash

HOST=$1
shift
CMD=$*

USER=root
PASS=calvin

sshpass -p $PASS ssh -n -o StrictHostKeyChecking=no -l $USER $HOST racadm $CMD
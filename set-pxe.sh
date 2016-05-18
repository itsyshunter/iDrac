#!/bin/bash

HOST=$1

if [ -z $HOST ]; then
  echo "Usage: $0 <host>"
  exit 1;
fi

RACADM="./idrac.sh ${HOST}"
#RACADM="docker run --rm -it justinclayton/racadm -r $HOST -u root -p calvin"

#Make a thing that echoes to stderr
echoerr() { cat <<< "$@" 1>&2; }

YELLOW=`tput setaf 3`
RED=`tput setaf 1`
RESET=`tput sgr0`

# Set the LOM3 to boot PXE, needed for Fuel and such
# Requires a NIC reset, which we do last for efficiency
echoerr "${YELLOW}${HOST}${RESET}:  Setting LOM3 to PXE boot"
$RACADM set NIC.NICConfig.3.LegacyBootProto PXE
echoerr "${YELLOW}${HOST}${RESET}:  Turning off PXE on LOM1"
$RACADM set NIC.NICConfig.1.LegacyBootProto NONE
echoerr "${YELLOW}${HOST}${RESET}:  Queueing LOM1 config change"
$RACADM jobqueue create NIC.Integrated.1-1-1
echoerr "${YELLOW}${HOST}${RESET}:  Resetting box to enable new config"
$RACADM jobqueue create NIC.Integrated.1-3-1 -s TIME_NOW -r pwrcycle

secs=60
while [ $secs -gt 0 ]; do
   echo -ne "Sleeping for ${YELLOW}$secs\033[0K${RESET} more seconds to wait for the reboot\r"
   sleep 1
   : $((secs--))
done


while true; do
  /usr/local/bin/fping $HOST > /dev/null
  if [ $? -eq 0 ]; then
    break
  fi
  echoerr "${YELLOW}${HOST} ${RED}is still down${RESET}"
  sleep 5
done

# I suspect that the above settings invalid this part of the config and therefore must
## must be done first.
echoerr "${YELLOW}${HOST}${RESET}:  Setting first boot device to PXE"
$RACADM set iDRAC.ServerBoot.FirstBootDevice PXE
sleep 10
echoerr "${YELLOW}${HOST}${RESET}:  Setting to boot to PXE always"
$RACADM set iDRAC.ServerBoot.BootOnce 0

sleep 10

$RACADM get iDRAC.ServerBoot
sleep 4
$RACADM get NIC.NICConfig.3
sleep 4
$RACADM get NIC.NICConfig.1


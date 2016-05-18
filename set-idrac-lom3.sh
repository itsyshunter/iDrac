#!/bin/bash

HOST=$1
VLAN=$2

if [ -z $HOST ] || [ -z $VLAN ]; then
  echo "Usage: $0 <host> <vlan number>"
  exit 1;
fi

RACADM="./idrac.sh ${HOST}"
#RACADM="docker run --rm -it justinclayton/racadm -r $HOST -u root -p calvin"

#Make a thing that echoes to stderr
echoerr() { cat <<< "$@" 1>&2; }

YELLOW=`tput setaf 3`
RED=`tput setaf 1`
RESET=`tput sgr0`

# Set the iDRAC to use LOM3, shared mode, and tagged vlan
echoerr "${YELLOW}${HOST}${RESET}:  Setting iDRAC to use LOM3 and vlan${VLAN}"
$RACADM set iDRAC.NIC.Selection LOM3
$RACADM set iDRAC.NIC.AutoDetect Enabled
$RACADM set iDRAC.NIC.VLanEnable Enabled
$RACADM set iDRAC.NIC.VLanID $VLAN

# Random want to haves
echoerr "${YELLOW}${HOST}${RESET}:  Setting basic tunings"
$RACADM set iDRAC.SSH.Timeout 300
$RACADM set iDRAC.Tuning.DefaultCredentialWarning Disabled

# Set the LOM3 to boot PXE, needed for Fuel and such
# Requires a NIC reset, which we do last for efficiency
echoerr "${YELLOW}${HOST}${RESET}:  Setting LOM3 to PXE boot"
$RACADM set NIC.NICConfig.3.LegacyBootProto PXE
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

$RACADM get iDRAC.NIC


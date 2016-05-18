#!/bin/bash

function debug() {
  if [ ! -z $DEBUG ]; then
    echo $1
    shift
    echo "$*"
    echo
  fi
}

function run_cmd() {
  local cmd=$1
  local file=${cmd// /-}
  if [ -s $DIR/$file ]; then
    echo "  * '${cmd}' already collected"
    # cat $DIR/$file
  else
    echo "  ** Collecting '${cmd}'..."
    $RACADM $cmd > $DIR/$file
    debug $cmd "$(cat $DIR/$file)"
  fi
}

while getopts df FLAG; do
  case $FLAG in
    d)
      DEBUG=1
      ;;
    f)
      FORCE=1
      ;;
  esac
done

shift $((OPTIND-1))

HOST=$1

RACADM="./idrac.sh ${HOST}"
DIR="./data/${HOST}"
mkdir -p $DIR

## COLLECT STUFF ##
echo "Collecting information for ${HOST}..."

if [ ! -z $FORCE ]; then
  echo "Forcing recollection..."
  rm -rf $DIR/*
fi

## collection commands to run
run_cmd "getsvctag"
run_cmd "getniccfg"
run_cmd "storage get controllers -o"
run_cmd "storage get pdisks -o"
run_cmd "storage get vdisks -o"
run_cmd "get bios.procsettings.procvirtualization"
run_cmd "get iDRAC.SSH.Timeout"
run_cmd "get iDRAC.Tuning.DefaultCredentialWarning"
run_cmd "racdump"
run_cmd "get bios.biosbootsettings.bootmode"

# just grab macs from racdump
if [ -s $DIR/macs ]; then
  echo "  * 'macs' already collected"
else
  grep Ethernet $DIR/racdump > $DIR/macs
fi

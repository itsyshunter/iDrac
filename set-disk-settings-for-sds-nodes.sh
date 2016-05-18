#!/bin/bash

function debug() {
  if [ ! -z $DEBUG ]; then
    echo "$*"
  fi
}

function submit_job_and_wait_for_completion() {
  echo "** Committing changes..."
  local job_id="$($RACADM jobqueue create --realtime RAID.Integrated.1-1 | grep 'Commit JID' | awk '{ print $4}')"
  while true; do
    debug "job_id is '${job_id}'"
    local status=$($RACADM jobqueue view -i $job_id | grep Status | cut -d= -f2)
    debug "status is '${status}'"
    case $status in
      Running) sleep 30 ;;
      "Ready For Execution") sleep 30 ;;
      Completed) break ;;
      Failed) break ;;
      *)
        echo "Unexpected status ${status}!"
        exit 1
        ;;
    esac
  done
  echo -e "** Changes applied!"
}

function racadm() {
  $RACADM ./idrac ${HOST} $*
}

function usage() {
  echo "usage: $0 [-h] [-d] [-wc] <host>"
  echo ""
  echo "-w: wipe existing raid config"
  echo "-c: create new raid config"
  echo ""
}

while getopts cdhw FLAG; do
  case $FLAG in
    c)
      CREATE=1
      ;;
    d)
      DEBUG=1
      ;;
    h)
      usage
      exit 0
      ;;
    w)
      WIPE=1
      ;;
  esac
done

if [ -z $WIPE ] && [ -z $CREATE ]; then
  echo "must use -c and/or -w"
  usage
  exit 1
fi

shift $((OPTIND-1))

HOST=$1

RACADM="./idrac.sh ${HOST}"

echo "### Altering RAID config for ${HOST} ###"

if [ ! -z $WIPE ]; then
  ## wipe everything out
  echo "** Destroying entire RAID config..."
  $RACADM storage resetconfig:RAID.Integrated.1-1

  submit_job_and_wait_for_completion

  $RACADM storage get vdisks
fi

if [ ! -z $CREATE ]; then

  echo "** Creating a single RAID 1 with write-back, read-ahead, and disabled disk cache on disks 24-25..."
  $RACADM storage createvd:RAID.Integrated.1-1 -rl r1 -wp wb -dcp disabled -rp ra -name os -pdkey:Disk.Bay.24:Enclosure.Internal.0-1:RAID.Integrated.1-1,Disk.Bay.25:Enclosure.Internal.0-1:RAID.Integrated.1-1

  echo "** Creating RAID 0 with write-back, no-read-ahead, and disabled disk cache on disks 0-5..."
  for i in {0..5}; do
    $RACADM storage createvd:RAID.Integrated.1-1 -rl r0 -wp wb -dcp disabled -rp nra -ss 256K -name ssd${i} -pdkey:Disk.Bay.${i}:Enclosure.Internal.0-1:RAID.Integrated.1-1
  done

  echo "** Creating RAID 0 with write-back, read-ahead, and disabled disk cache on disks 6-23..."
  for i in {6..23}; do
    $RACADM storage createvd:RAID.Integrated.1-1 -rl r0 -wp wb -dcp disabled -rp ra -ss 256K -name sas${i} -pdkey:Disk.Bay.${i}:Enclosure.Internal.0-1:RAID.Integrated.1-1
  done

  submit_job_and_wait_for_completion

  $RACADM storage get vdisks -o
fi

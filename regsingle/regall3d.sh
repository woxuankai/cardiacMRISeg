#!/bin/bash
#OPTS='-d -v'
OPTS="$@"
REG='./doreg.sh'
SLP=2

sleep $SLP
$REG d0_v0 d1_v0 $OPTS 2>/dev/null | grep -i dice &
sleep $SLP
$REG d1_v0 d0_v0 $OPTS 2>/dev/null | grep -i dice &
sleep $SLP
$REG d0_v0 d2_v0 $OPTS 2>/dev/null | grep -i dice &
sleep $SLP
$REG d1_v0 d2_v0 $OPTS 2>/dev/null | grep -i dice &
sleep $SLP
$REG d2_v0 d0_v0 $OPTS 2>/dev/null | grep -i dice &
sleep $SLP
$REG d2_v0 d1_v0 $OPTS 2>/dev/null | grep -i dice &
sleep $SLP
wait
exit 0

#!/bin/bash
OPTS='-d -v'
REG='./doreg.sh'


$REG d0_v0 d1_v0 $OPTS 2>/dev/null | grep -i dice &
$REG d1_v0 d0_v0 $OPTS 2>/dev/null | grep -i dice &
$REG d0_v0 d2_v0 $OPTS 2>/dev/null | grep -i dice &
$REG d1_v0 d2_v0 $OPTS 2>/dev/null | grep -i dice &
$REG d2_v0 d0_v0 $OPTS 2>/dev/null | grep -i dice &
$REG d2_v0 d1_v0 $OPTS 2>/dev/null | grep -i dice &
wait
exit 0

#!/bin/bash
OPTS='-d -v'
REG='./doreg.sh'

#$REG d0 d1 $OPTS 2>/dev/null | grep -i dice &
#$REG d0 d2 $OPTS 2>/dev/null | grep -i dice &
#$REG d1 d0 $OPTS 2>/dev/null | grep -i dice &
#$REG d1 d2 $OPTS 2>/dev/null | grep -i dice &
#$REG d2 d0 $OPTS 2>/dev/null | grep -i dice &
#$REG d2 d1 $OPTS 2>/dev/null | grep -i dice &


$REG d7 d12 $OPTS 2>/dev/null | grep -i dice &
$REG d8 d12 $OPTS 2>/dev/null | grep -i dice &
$REG d12 d7 $OPTS 2>/dev/null | grep -i dice &
$REG d12 d8 $OPTS 2>/dev/null | grep -i dice &
$REG d7 d8 $OPTS 2>/dev/null | grep -i dice &
$REG d8 d7 $OPTS 2>/dev/null | grep -i dice &
wait
exit 0

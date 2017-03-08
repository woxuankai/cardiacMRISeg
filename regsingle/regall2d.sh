#!/bin/bash
OPTS='-d'
REG='./doreg.sh'

#$REG d0 d1 2 $OPTS 2>/dev/null | grep -i dice &
#$REG d0 d2 2 $OPTS 2>/dev/null | grep -i dice &
#$REG d1 d0 2 $OPTS 2>/dev/null | grep -i dice &
#$REG d1 d2 2 $OPTS 2>/dev/null | grep -i dice &
#$REG d2 d0 2 $OPTS 2>/dev/null | grep -i dice &
#$REG d2 d1 2 $OPTS 2>/dev/null | grep -i dice &


$REG d7 d12 2 $OPTS 2>/dev/null | grep -i dice &
$REG d8 d12 2 $OPTS 2>/dev/null | grep -i dice &
$REG d12 d7 2 $OPTS 2>/dev/null | grep -i dice &
$REG d12 d8 2 $OPTS 2>/dev/null | grep -i dice &
$REG d7 d8 2 $OPTS 2>/dev/null | grep -i dice &
$REG d8 d7 2 $OPTS 2>/dev/null | grep -i dice &
wait
exit 0

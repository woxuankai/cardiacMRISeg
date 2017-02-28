#!/bin/bash
OPTS="-d -v"
./BSpline.sh d0 d1 $OPTS 2>/dev/null | grep -i dice &
./BSpline.sh d0 d2 $OPTS 2>/dev/null | grep -i dice &
./BSpline.sh d1 d0 $OPTS 2>/dev/null | grep -i dice &
./BSpline.sh d1 d2 $OPTS 2>/dev/null | grep -i dice &
./BSpline.sh d2 d0 $OPTS 2>/dev/null | grep -i dice &
./BSpline.sh d2 d1 $OPTS 2>/dev/null | grep -i dice &
wait
exit 0

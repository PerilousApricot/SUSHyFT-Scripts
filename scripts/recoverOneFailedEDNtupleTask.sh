#!/bin/bash

# scripts/recoverOneFailedEDNtupleTask.sh failed-autofwlite.txt

TESTINPUT=$1
crab -resubmit $(sed 's#.*res/crab_fjr_\(.*\).xml$#\1#' $TESTINPUT | tr '\n' ',' | sed 's/,\+$//') -c $(sed 's#.*FJR: \(.*\)/res/crab_fjr.*#\1#' $TESTINPUT | head -n 1)
RETVAL=$?
if [[ $RETVAL -eq 0 ]]; then
    # rm $TESTINPUT
    exit 0
fi
exit $RETVAL

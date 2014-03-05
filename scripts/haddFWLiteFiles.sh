#!/bin/bash

# haddFWLiteFiles.sh <output file> <file 1> <file 2> ..
echo "args $@"

OUTPUT=$1
shift
set -x
[[ -e $OUTPUT ]] && rm -f $OUTPUT
hadd $OUTPUT $@
set +x
EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
    echo "Got error in hadd, aborting"
    rm $OUTPUT
    echo "$@" >> $OUTPUT.FAIL
fi
echo "Normal exit"
exit $EXIT_CODE

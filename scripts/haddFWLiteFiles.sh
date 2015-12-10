#!/bin/bash

# haddFWLiteFiles.sh <output file> <file 1> <file 2> ..
echo "args $@"

OUTPUT=$1
shift
set -x
if [[ $# -eq 0 ]]; then
    echo "No input files?"
    rm -f $OUTPUT
    exit 1
fi
[[ -e $OUTPUT ]] && rm -f $OUTPUT
hadd -f0 $OUTPUT $@
set +x
EXIT_CODE=$?
if [[ $EXIT_CODE -ne 0 ]]; then
    echo "Got error in hadd, aborting"
    rm $OUTPUT
    echo "$@" >> $OUTPUT.FAIL
fi
exit $EXIT_CODE

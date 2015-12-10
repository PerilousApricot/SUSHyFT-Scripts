#!/bin/bash

mkdir -p $SHYFT_BASE/state/$SHYFT_MODE

getStitchedInfo.py $SHYFT_BASE/config/$SHYFT_MODE/stitchConfig.cfg > \
                                $SHYFT_BASE/state/$SHYFT_MODE/stitchConfig.json

SYSTEMATIC_LIST=$(ls $SHYFT_BASE/data/auto_hadd/ | sed 's/^\([^_]*\)_.*/\1/' | sort | uniq)
function process_file() {
    SYST=$1
    FILE=$2
    echo -n "."
    FILE_BASENAME=$(basename $FILE)
    FILE_NOPREFIX=${FILE_BASENAME#${SYST}_}
    getNumberProcessed.py $FILE > $SHYFT_BASE/state/$SYST/processed/${FILE_NOPREFIX}.json
    getRawEventCount.py $FILE > $SHYFT_BASE/state/$SYST/raw/${FILE_NOPREFIX}.json
}
export -f process_file

for SYST in $SYSTEMATIC_LIST; do
    echo -n "Processing $SYST: "
    mkdir -p $SHYFT_BASE/state/$SYST/{processed,raw}
    echo $SHYFT_BASE/data/auto_hadd/${SYST}_*.root | tr ' ' '\n' | \
        xargs -I{} -n 1 -P 8 bash -c "process_file $SYST {}"
    echo " - done."
done

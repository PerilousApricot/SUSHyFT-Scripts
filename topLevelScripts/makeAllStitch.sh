#!/bin/bash
if [[ ! -d ${SUSHYFT_STITCHED_PATH} ]]; then
    mkdir -p ${SUSHYFT_STITCHED_PATH}
fi
( for CFG in $SUSHYFT_BASE/config/$SUSHYFT_MODE/stitchSystematicConfigs/*.cfg; do
    COMMAND_TO_RUN="stitch.py ${SUSHYFT_REBIN_PATH} ${SUSHYFT_STITCHED_PATH} $SUSHYFT_BASE/config/$SUSHYFT_MODE/stitchConfig.cfg"
    OUTPUTS=""
    INPUTS=""
    while read LINE; do
        # not sure how to break this up
        if [[ -z $OUTPUTS ]]; then
            OUTPUTS=$LINE
        else
            INPUTS="$INPUTS $LINE"
        fi
    done < <($COMMAND_TO_RUN $CFG --getInputFiles)
    echo "runIfChanged.sh $OUTPUTS $INPUTS `which stitch.py` $SUSHYFT_BASE/config/$SUSHYFT_MODE/stitchConfig.cfg $CFG -- stitch.py ${SUSHYFT_REBIN_PATH} ${SUSHYFT_STITCHED_PATH} $SUSHYFT_BASE/config/$SUSHYFT_MODE/stitchConfig.cfg $CFG"
done ) #|  parallel -j ${SUSHYFT_DOUBLE_CORE_COUNT} --eta --progress

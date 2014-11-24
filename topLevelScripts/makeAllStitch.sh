#!/bin/bash
if [[ ! -d ${SHYFT_STITCHED_PATH}/${SHYFT_MODE} ]]; then
    mkdir -p ${SHYFT_STITCHED_PATH}/${SHYFT_MODE}
fi
( for CFG in $SHYFT_BASE/config/$SHYFT_MODE/stitchSystematicConfigs/*.cfg; do
    COMMAND_TO_RUN="stitch.py ${SHYFT_REBIN_PATH}/${SHYFT_MODE} ${SHYFT_STITCHED_PATH}/${SHYFT_MODE} $SHYFT_BASE/config/$SHYFT_MODE/stitchConfig.cfg"
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
    echo "runIfChanged.sh $OUTPUTS $INPUTS `which stitch.py` $SHYFT_BASE/config/$SHYFT_MODE/stitchConfig.cfg $CFG -- stitch.py ${SHYFT_REBIN_PATH}/${SHYFT_MODE} ${SHYFT_STITCHED_PATH}/${SHYFT_MODE} $SHYFT_BASE/config/$SHYFT_MODE/stitchConfig.cfg $CFG"
done ) |  parallel -j ${SHYFT_DOUBLE_CORE_COUNT} --eta --progress

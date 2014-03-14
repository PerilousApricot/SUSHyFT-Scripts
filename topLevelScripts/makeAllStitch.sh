#!/bin/bash
if [[ ! -d ${SUSHYFT_STITCHED_PATH} ]]; then
    mkdir -p ${SUSHYFT_STITCHED_PATH}
fi
rm -f ${SUSHYFT_STITCHED_PATH}/*.root
ls $SUSHYFT_BASE/config/$SUSHYFT_MODE/stitchSystematicConfigs/*.cfg | parallel -n 1 -P 10 stitch.py ${SUSHYFT_REBIN_PATH} ${SUSHYFT_STITCHED_PATH} $SUSHYFT_BASE/config/$SUSHYFT_MODE/stitchConfig.cfg

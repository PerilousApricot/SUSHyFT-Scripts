#!/bin/bash

# edmMakePhDThesis was a sham, this is the REAL thing.
set -e
if [[ -d ${SUSHYFT_EDNTUPLE_PATH} ]]; then
    makeAllFWLite.sh
fi
if [[ -d ${SUSHYFT_FWLITE_PATH} ]]; then
    makeAllHadd.sh
fi
if [[ -d ${SUSHYFT_HADD_PATH} ]]; then
    makeAllRebin.sh
fi
if [[ -d ${SUSHYFT_REBIN_PATH} ]]; then
    makeAllStitch.sh
fi
if [[ -d ${SUSHYFT_STITCHED_PATH} ]]; then
    makeAllCopyHist.sh
fi
if [[ -d ${SUSHYFT_EDNTUPLE_PATH} ]]; then
    makeAllLumiCalc.sh
fi
if [[ -d ${SUSHYFT_COPYHIST_PATH} ]]; then
    makeAllQCDFits.sh
fi

# If you're not making the histograms, what's the point?
makeAllFits.sh

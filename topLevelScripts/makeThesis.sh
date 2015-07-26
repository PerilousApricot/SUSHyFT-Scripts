#!/bin/bash

# edmMakePhDThesis was a sham, this is the REAL thing.
set -ex
if [[ -d ${SHYFT_EDNTUPLE_PATH} ]]; then
    makeAllFWLite.sh
fi
if [[ -d ${SHYFT_FWLITE_PATH} ]]; then
    makeAllHadd.sh
fi
if [[ -d ${SHYFT_HADD_PATH} ]]; then
    makeAllRebin.sh
fi
if [[ -d ${SHYFT_REBIN_PATH} ]]; then
    makeAllStitch.sh
fi
plotStitched.py &
if [[ -d ${SHYFT_STITCHED_PATH} ]]; then
    makeAllCopyHist.sh
fi
if [[ -d ${SHYFT_EDNTUPLE_PATH} ]]; then
    #makeAllLumiCalc.sh
    :
fi
if [[ -d ${SHYFT_COPYHIST_PATH} ]]; then
    makeAllQCD.sh
fi

makeAllSystematics.sh

# If you're not making the histograms, what's the point?
makeAllFits.sh
wait

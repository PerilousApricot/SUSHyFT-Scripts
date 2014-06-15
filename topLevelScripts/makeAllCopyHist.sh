#!/bin/bash
set -x
if [[ ! -d ${SUSHYFT_COPYHIST_PATH} ]];then
    mkdir -p ${SUSHYFT_COPYHIST_PATH}
fi

multi.pl --match ${SUSHYFT_STITCHED_PATH}/${SUSHYFT_MODE}/%.root runIfChanged.sh ${SUSHYFT_COPYHIST_PATH}/${SUSHYFT_MODE}/central_%.root ${SUSHYFT_STITCHED_PATH}/${SUSHYFT_MODE}/%.root ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/copyHistConfigs/nominal.config -- copyHistograms.py ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/copyHistConfigs/nominal.config ${SUSHYFT_COPYHIST_PATH}/${SUSHYFT_MODE}/central_%.root file=${SUSHYFT_STITCHED_PATH}/${SUSHYFT_MODE}/%.root

runIfChanged.sh ${SUSHYFT_COPYHIST_PATH}/${SUSHYFT_MODE}/metfit.root ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/copyHistConfigs/metfit.config ${SUSHYFT_STITCHED_PATH}/${SUSHYFT_MODE}/metfit.root -- copyHistograms.py ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/copyHistConfigs/metfit.config ${SUSHYFT_COPYHIST_PATH}/${SUSHYFT_MODE}/metfit.root file=${SUSHYFT_STITCHED_PATH}/${SUSHYFT_MODE}/metfit.root

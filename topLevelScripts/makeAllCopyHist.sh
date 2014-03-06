#!/bin/bash
set -x
if [[ ! -d ${SUSHYFT_COPYHIST_PATH} ]];then
    mkdir -p ${SUSHYFT_COPYHIST_PATH}
fi

multi.pl --match ${SUSHYFT_STITCHED_PATH}/stitched_%.root runIfChanged.sh ${SUSHYFT_COPYHIST_PATH}/central_%.root ${SUSHYFT_STITCHED_PATH}/stitched_%.root ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/copyHistConfigs/nominal.config -- copyHistograms.py ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/copyHistConfigs/nominal.config ${SUSHYFT_COPYHIST_PATH}/central_%.root file=${SUSHYFT_STITCHED_PATH}/stitched_%.root

runIfChanged.sh ${SUSHYFT_COPYHIST_PATH}/metfit.root ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/copyHistConfigs/metfit.config ${SUSHYFT_STITCHED_PATH}/stitched_metfit.root -- copyHistograms.py ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/copyHistConfigs/metfit.config ${SUSHYFT_COPYHIST_PATH}/metfit.root file=${SUSHYFT_STITCHED_PATH}/stitched_metfit.root

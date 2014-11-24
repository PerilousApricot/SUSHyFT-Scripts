#!/bin/bash
set -x
if [[ ! -d ${SHYFT_COPYHIST_PATH} ]];then
    mkdir -p ${SHYFT_COPYHIST_PATH}
fi

multi.pl --match ${SHYFT_STITCHED_PATH}/${SHYFT_MODE}/%.root runIfChanged.sh ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_%.root ${SHYFT_STITCHED_PATH}/${SHYFT_MODE}/%.root ${SHYFT_BASE}/config/${SHYFT_MODE}/copyHistConfigs/nominal.config -- copyHistograms.py ${SHYFT_BASE}/config/${SHYFT_MODE}/copyHistConfigs/nominal.config ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_%.root file=${SHYFT_STITCHED_PATH}/${SHYFT_MODE}/%.root

runIfChanged.sh ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/metfit.root ${SHYFT_BASE}/config/${SHYFT_MODE}/copyHistConfigs/metfit.config ${SHYFT_STITCHED_PATH}/${SHYFT_MODE}/metfit.root -- copyHistograms.py ${SHYFT_BASE}/config/${SHYFT_MODE}/copyHistConfigs/metfit.config ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/metfit.root file=${SHYFT_STITCHED_PATH}/${SHYFT_MODE}/metfit.root

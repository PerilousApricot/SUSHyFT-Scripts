#!/bin/bash
if [[ ! -d ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/preQCD ]];then
    mkdir -p ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/preQCD
fi
# Make the copyHist histograms
multi.pl --match ${SHYFT_STITCHED_PATH}/${SHYFT_MODE}/%.root runIfChanged.sh ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/preQCD/central_%.root ${SHYFT_STITCHED_PATH}/${SHYFT_MODE}/%.root ${SHYFT_BASE}/config/${SHYFT_MODE}/copyHistConfigs/nominal.config -- copyHistograms.py ${SHYFT_BASE}/config/${SHYFT_MODE}/copyHistConfigs/nominal.config ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/preQCD/central_%.root file=${SHYFT_STITCHED_PATH}/${SHYFT_MODE}/%.root

# Normalize them to QCD and move to the right place
multi.pl --match ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/preQCD/%.root runIfChanged.sh ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/%.root `which normalizeQCD.py` ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/preQCD/%.root -- normalizeQCD.py ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/preQCD/%.root ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/%.root

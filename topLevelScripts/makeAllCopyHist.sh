#!/bin/bash
if [[ ! -d ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/preQCD ]];then
    mkdir -p ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/preQCD
fi
if [[ ! -d ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/scaledQCD ]];then
    mkdir -p ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/scaledQCD
fi    

# Don't normalize anytyhing
multi.pl --match ${SHYFT_STITCHED_PATH}/${SHYFT_MODE}/%.root runIfChanged.sh ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_%.root ${SHYFT_STITCHED_PATH}/${SHYFT_MODE}/%.root ${SHYFT_BASE}/config/${SHYFT_MODE}/copyHistConfigs/nominal.config -- copyHistograms.py ${SHYFT_BASE}/config/${SHYFT_MODE}/copyHistConfigs/nominal.config ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_%.root file=${SHYFT_STITCHED_PATH}/${SHYFT_MODE}/%.root


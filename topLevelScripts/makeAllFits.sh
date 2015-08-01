#!/bin/bash

source ${SHYFT_BASE}/config/${SHYFT_MODE}/config.sh

# This really really depends on having the proper data lumi set
LUMI_FILE=${SHYFT_BASE}/state/lumisum_${SHYFT_EDNTUPLE_VERSION}_SingleMu.txt
if [[ ! -e ${LUMI_FILE} ]];then
    echo "You need to run makeAllLumiCalc.sh to get an accurate lumi calculation!"
    echo "  (Searched for ${LUMI_FILE})"
    exit 1
fi

LUMIFILE=${SHYFT_BASE}/state/lumisum_${SHYFT_EDNTUPLE_VERSION}_SingleMu.txt
if [[ ${SHYFT_MODE} == test_* ]]; then
    LUMIFILE=${SHYFT_BASE}/config/${SHYFT_MODE}/lumi.txt
fi

# expand these filenames to the full paths and make it so it can point to the
# fitter easily
# SHYFT_SYST_LIST = ( btag.mrf ttag.mrf )
# turns into includeFiles=${SHYFT_BASE}/state/${SHYFT_MODE}/btag.mrf,${SHYFT_BASE}/state/${SHYFT_MODE}
SHYFT_SYSTEMATIC_LIST=( btag_sf.mrf qcd.mrf )
if [ -n "${SHYFT_SYSTEMATIC_LIST}" ]; then
    SYSTEMATIC_STRING="$(echo ${SHYFT_SYSTEMATIC_LIST[*]} | tr ' ' ',' )"
    CONSTRUCTED_ARRAY=( )
    for SYST in ${SHYFT_SYSTEMATIC_LIST[@]}; do
        CONSTRUCTED_ARRAY+=( ${SHYFT_BASE}/state/${SHYFT_MODE}/$SYST )
    done
    SYSTEMATIC_STRING="includeFiles=$(echo ${CONSTRUCTED_ARRAY[*]} | tr ' ' ',')"
fi
SHYFT_QCD_ONLY_SYSTEMATIC="includeFiles=${SHYFT_BASE}/state/${SHYFT_MODE}/qcd.mrf"
# All that for this. Run the fit.
mkdir -p ${SHYFT_BASE}/output/${SHYFT_MODE}
pushd ${SHYFT_BASE}
#multiRegionFitter.exe ${SHYFT_BASE}/config/${SHYFT_MODE}/fitConfigs/nominal.mrf templateFile=data/auto_copyhist/${SHYFT_MODE}/central_nominal.root fitData=1 output=${SHYFT_BASE}/output/${SHYFT_MODE}/central_nominal $SYSTEMATIC_STRING savePlots=1 saveTemplates=1 showCorrelations=1 dominos=1 intlumi=$(cat ${LUMIFILE}) logplots=1
set -x
multiRegionFitter.exe ${SHYFT_BASE}/config/${SHYFT_MODE}/fitConfigs/nominal.mrf templateFile=data/auto_copyhist/${SHYFT_MODE}/central_nominal.root fitData=1 output=${SHYFT_BASE}/output/${SHYFT_MODE}/central_nominal $SYSTEMATIC_STRING savePlots=1 saveTemplates=1 showCorrelations=1 dominos=1 logplots=1 | tee ${SHYFT_BASE}/output/${SHYFT_MODE}/central_nominal.txt

multiRegionFitter.exe ${SHYFT_BASE}/config/${SHYFT_MODE}/fitConfigs/nominal.mrf templateFile=data/auto_copyhist/${SHYFT_MODE}/central_nominal.root fitData=1 output=${SHYFT_BASE}/output/${SHYFT_MODE}/central_nosyst $SHYFT_QCD_ONLY_SYSTEMATIC savePlots=1 saveTemplates=1 showCorrelations=1 dominos=1 logplots=1 | tee ${SHYFT_BASE}/output/${SHYFT_MODE}/central_nosyst.txt

#multiRegionFitter.exe ${SHYFT_BASE}/config/${SHYFT_MODE}/fitConfigs/nominal.mrf templateFile=data/auto_copyhist/${SHYFT_MODE}/central_flipiso.root fitData=1 output=${SHYFT_BASE}/output/${SHYFT_MODE}/central_flipiso $SYSTEMATIC_STRING savePlots=1 saveTemplates=1 showCorrelations=1 dominos=1 logplots=1



#multiRegionFitter.exe ${SHYFT_BASE}/config/${SHYFT_MODE}/fitConfigs/nominal.mrf templateFile=data/auto_copyhist/${SHYFT_MODE}/central_nominal.root fitData=1 output=${SHYFT_BASE}/output/${SHYFT_MODE}/central_nominal $SYSTEMATIC_STRING savePlots=1 saveTemplates=1 showCorrelations=1 dominos=1 intlumi=$(cat ${LUMIFILE})
popd

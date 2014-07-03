#!/bin/bash

source ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/config.sh

# This really really depends on having the proper data lumi set
if [[ ! -e ${SUSHYFT_BASE}/state/lumisum_${SUSHYFT_EDNTUPLE_VERSION}_SingleMu.txt ]];then
    echo "You need to run makeAllLumiCalc.sh to get an accurate lumi calculation!"
    exit 1
fi

LUMIFILE=${SUSHYFT_BASE}/state/lumisum_${SUSHYFT_EDNTUPLE_VERSION}_SingleMu.txt
if [[ ${SUSHYFT_MODE} == test_* ]]; then
    LUMIFILE=${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/lumi.txt
fi

# expand these filenames to the full paths and make it so it can point to the
# fitter easily
# SUSHYFT_SYST_LIST = ( btag.mrf ttag.mrf )
# turns into includeFiles=${SUSHYFT_BASE}/state/${SUSHYFT_MODE}/btag.mrf,${SUSHYFT_BASE}/state/${SUSHYFT_MODE}

if [ -n "${SUSHYFT_SYSTEMATIC_LIST}" ]; then
    SYSTEMATIC_STRING="$(echo ${SUSHYFT_SYSTEMATIC_LIST[*]} | tr ' ' ',' )"
    CONSTRUCTED_ARRAY=( )
    for SYST in ${SUSHYFT_SYSTEMATIC_LIST[@]}; do
        CONSTRUCTED_ARRAY+=( state/${SUSHYFT_MODE}/$SYST )
    done
    SYSTEMATIC_STRING="includeFiles=$(echo ${CONSTRUCTED_ARRAY[*]} | tr ' ' ',')"
fi

# All that for this. Run the fit.
mkdir -p ${SUSHYFT_BASE}/output/${SUSHYFT_MODE}
pushd ${SUSHYFT_BASE}
multiRegionFitter.exe ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/fitConfigs/nominal.mrf templateFile=data/auto_copyhist/${SUSHYFT_MODE}/central_nominal.root fitData=1 output=${SUSHYFT_BASE}/output/${SUSHYFT_MODE}/central_nominal $SYSTEMATIC_STRING savePlots=1 saveTemplates=1 showCorrelations=1 dominos=1 intlumi=$(cat ${LUMIFILE}) logplots=1
popd

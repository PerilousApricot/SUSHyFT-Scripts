#!/bin/bash

OUTPUT_PATH=${SHYFT_BASE}/output/${SHYFT_MODE}/qcdfit
if [ ! -d $OUTPUT_PATH/raw ]; then
    mkdir -p $OUTPUT_PATH/raw
fi
groupNames=()
groupValues=()
# TODO: generate this automatically
for JET in 1 2 3 4 5; do
    for BTAG in 0 1 2; do
        for TTAG in 0 1; do
            if [[ $(($BTAG + $TTAG)) -gt ${JET} ]]; then
                continue
            fi
            groupNames+=("_MET_${JET}j_${BTAG}b_${TTAG}t")
            groupValues+=("${JET}_JET_${BTAG}_BJet_${TTAG}_TJet")
        done
    done
done

# First, move the stiched file over
runIfChanged.sh ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/preQCD/metfit.root ${SHYFT_BASE}/config/${SHYFT_MODE}/copyHistConfigs/metfit.config ${SHYFT_STITCHED_PATH}/${SHYFT_MODE}/noMET.root -- copyHistograms.py ${SHYFT_BASE}/config/${SHYFT_MODE}/copyHistConfigs/metfit.config ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/preQCD/metfit.root file=${SHYFT_STITCHED_PATH}/${SHYFT_MODE}/qcdMode.root

# Then do the different fits
set -x
for m in "${!groupNames[@]}"; do
    multiRegionFitter.exe metfit.mrf templateFile=${SHYFT_BASE}/data/auto_copyhist/${SHYFT_MODE}/preQCD/metfit.root fitData=1 output=$OUTPUT_PATH/${groupNames[$m]} savePlots=1 saveTemplates=1 showCorrelations=1 dominos=1 groupNames=${groupNames[$m]} groupStrings=${groupValues[$m]} > $OUTPUT_PATH/raw/${groupNames[$m]}
done

# Finally, generate the QCD .mrf
qcdToMrf.sh > ${SHYFT_BASE}/state/${SHYFT_MODE}/qcd.mrf

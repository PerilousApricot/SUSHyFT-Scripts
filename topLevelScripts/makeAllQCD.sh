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

for m in "${!groupNames[@]}"; do
    echo ${groupNames[$m]}
    echo ${groupValues[$m]}
    multiRegionFitter.exe metfit.mrf templateFile=data/auto_copyhist/st-nominal/metfit.root fitData=1 output=$OUTPUT_PATH/${groupNames[$m]} savePlots=1 saveTemplates=1 showCorrelations=1 dominos=1 logplots=1 groupNames=${groupNames[$m]} groupStrings=${groupValues[$m]} > $OUTPUT_PATH/raw/${groupNames[$m]}
done

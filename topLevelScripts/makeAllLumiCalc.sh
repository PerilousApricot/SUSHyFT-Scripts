#!/bin/bash

if [[ -z ${CRABDIR} ]]; then
    echo "WARNING: No CRAB installation was sourced, this probably script needs"
    echo "         CRAB to function."
else
    # get the json from crab
    toProcess=( )
    for DIR in ${SUSHYFT_EDNTUPLE_PATH}/*{MET,SingleMu}*; do
        if [[ ! -d $DIR/res || ! -d $DIR/share ]]; then
            continue
        fi
        toProcess+=("runIfChanged.sh $DIR/res/lumiSummary.json $DIR/res/*.xml -- crab -report -c $DIR")
    done
    echo "Executing ${#toProcess[@]} jobs"
    ( for ((i = 0; i < ${#toProcess[@]}; i++)); do
        echo "${toProcess[$i]}"
    done; ) | parallel -j 16 --eta --progress
fi

# extract the lumi
toProcess=( )
for DIR in ${SUSHYFT_EDNTUPLE_PATH}/*{MET,SingleMu}*; do
    if [[ ! -d $DIR/res || ! -d $DIR/share ]]; then
        continue
    fi
    toProcess+=("runIfChanged.sh $DIR/pixelLumiCalc.txt $DIR/res/lumiSummary.json -- stdoutWrapper.sh $DIR/pixelLumiCalc.txt pixelLumiCalc.py overview -i $DIR/res/lumiSummary.json")
done
echo "Executing ${#toProcess[@]} jobs"
( for ((i = 0; i < ${#toProcess[@]}; i++)); do
    echo "${toProcess[$i]}"
done; ) | parallel -j 16 --eta --progress --verbose

for PD in MET SingleMu; do
    runIfChanged.sh $SUSHYFT_STATE_PATH/lumisum_${SUSHYFT_EDNTUPLE_VERSION}_${PD}.txt `which sumLumisFromLumiCalcOutput.py` ${SUSHYFT_EDNTUPLE_PATH}/crab_${SUSHYFT_EDNTUPLE_VERSION}_${PD}*/pixelLumiCalc.txt -- stdoutWrapper.sh $SUSHYFT_STATE_PATH/lumisum_${SUSHYFT_EDNTUPLE_VERSION}_${PD}.txt sumLumisFromLumiCalcOutput.py ${SUSHYFT_EDNTUPLE_PATH}/crab_${SUSHYFT_EDNTUPLE_VERSION}_${PD}*/pixelLumiCalc.txt
done

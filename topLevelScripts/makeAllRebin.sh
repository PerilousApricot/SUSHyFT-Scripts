#!/bin/bash

# To keep the FWLite files as broad as possible, they keep all of the bings
# this script removes/combines unneeded bins
source $SUSHYFT_BASE/scripts/functions.sh
toProcess=( )
echo "Gathering jobs to process"
while read DATASET; do
    SHORTNAME=$(getDatasetShortname $DATASET)
    FWLITE_DIR=$SUSHYFT_EDNTUPLE_PATH/crab_${SUSHYFT_EDNTUPLE_VERSION}_${SHORTNAME}
    BASEDIR=$(basename $FWLITE_DIR)
    case $SHORTNAME in
        Single*)
            IS_DATA=1
            ;;
        MET*)
            IS_DATA=1
            ;;
        *)
            IS_DATA=0
            ;;
    esac
    while read OUTNAME TESTREGEX SYSTDATA SYSTLINE; do
        if [[ $IS_DATA -eq 1 && $SYSTDATA -eq 0 ]]; then
            continue
        fi
        if [[ ! $BASEDIR =~ ${TESTREGEX} ]]; then
            continue
        fi
        DIR=$SUSHYFT_FWLITE_PATH/$BASEDIR/$OUTNAME
        DATASET_WCRAB=$( echo $DIR | tr '/' ' ' | awk '{ print $(NF-1) }' )
        DATASET=$( echo $DATASET_WCRAB | perl -pe 's|crab_.*?_(.*)|\1|' )
        SYSTEMATIC=$( echo $DIR | tr '/' ' ' | awk '{ print $(NF) }' )
        HADD_INPUT_FILE=$SUSHYFT_HADD_PATH/${SYSTEMATIC}_${DATASET}.root
        toProcess+=("runIfChanged.sh $SUSHYFT_REBIN_PATH/${SUSHYFT_MODE}_${SYSTEMATIC}_${DATASET}.root $HADD_INPUT_FILE -- rebinHists.py --tagMode=${SUSHYFT_MODE} --outDir=$SUSHYFT_REBIN_PATH $HADD_INPUT_FILE")
    done < $SUSHYFT_BASE/config/$SUSHYFT_MODE/fwliteSystematicsList.txt
done < $SUSHYFT_BASE/config/$SUSHYFT_MODE/input_pat.txt

echo "Executing ${#toProcess[@]} jobs"
( for ((i = 0; i < ${#toProcess[@]}; i++)); do
    echo "${toProcess[$i]}"
done; ) | parallel -j 16 --eta --progress


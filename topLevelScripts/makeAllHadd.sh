#!/bin/bash

# hadds all the fwlite files together in a sensible way
source $SHYFT_BASE/scripts/functions.sh
toProcess=( )
echo "Gathering jobs to process"
while read DATASET; do
    SHORTNAME=$(getDatasetShortname $DATASET)                                      
    echo "Processing $SHORTNAME"                                                   
    FWLITE_DIR=$SHYFT_EDNTUPLE_PATH/crab_${SHYFT_EDNTUPLE_VERSION}_${SHORTNAME}
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
        if [[ ! $BASEDIR =~ "$TESTREGEX" ]]; then
            continue
        fi
        DIR=$SHYFT_FWLITE_PATH/$BASEDIR/$OUTNAME
        if [[ ! -n "$(find $DIR -maxdepth 1 -name '*.root' -print -quit)" ]]; then
            continue
        fi
        DATASET_WCRAB=$( echo $DIR | tr '/' ' ' | awk '{ print $(NF-1) }' )
        DATASET=$( echo $DATASET_WCRAB | perl -pe 's|crab_.*?_(.*)|\1|' )
        SYSTEMATIC=$( echo $DIR | tr '/' ' ' | awk '{ print $(NF) }' )
        toProcess+=("runIfChanged.sh $SHYFT_HADD_PATH/${SYSTEMATIC}_${DATASET}.root $DIR/*.root -- haddFWLiteFiles.sh $SHYFT_HADD_PATH/${SYSTEMATIC}_${DATASET}.root $DIR/*.root")
    done < $SHYFT_BASE/config/$SHYFT_MODE/fwliteSystematicsList.txt
done < $SHYFT_BASE/config/$SHYFT_MODE/input_pat.txt

echo "Executing ${#toProcess[@]} jobs"
( for ((i = 0; i < ${#toProcess[@]}; i++)); do
    echo "${toProcess[$i]}"
done; ) | parallel -j 30 --eta --progress


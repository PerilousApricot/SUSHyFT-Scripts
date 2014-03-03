#!/bin/bash
FWLITE_BASE=/scratch/meloam/auto_fwlite
HADD_BASE=/scratch/meloam/auto_hadd
CURR_VERSION='v2'
# hadds all the fwlite files together in a sensible way
if [[ ! -d $HADD_BASE/state ]]; then
    mkdir -p $HADD_BASE
    mkdir -p $HADD_BASE/state
fi
DIR=$1
DATASET_WCRAB=$( echo $DIR | tr '/' ' ' | awk '{ print $(NF-1) }' )
DATASET=$( echo $DATASET_WCRAB | perl -pe 's|crab_.*?_(.*)|\1|' )
SYSTEMATIC=$( echo $DIR | tr '/' ' ' | awk '{ print $(NF) }' )
INPUT_STATE=$( ls -la $DIR/* | sort | md5sum )
if [[ -e $HADD_BASE/state/${SYSTEMATIC}_${DATASET} ]]; then
    if [[ $( cat $HADD_BASE/state/${SYSTEMATIC}_${DATASET} ) == $INPUT_STATE ]]; then
        echo "Skipping ${SYSTEMATIC}_${DATASET}"
        exit 0
    fi
fi
set -x
echo "Processing ${SYSTEMATIC}_${DATASET}"
echo "$INPUT_STATE" > $HADD_BASE/state/${SYSTEMATIC}_${DATASET}
set +x
rm $HADD_BASE/${SYSTEMATIC}_${DATASET}.root
hadd $HADD_BASE/${SYSTEMATIC}_${DATASET}.root $DIR/*.root
if [[ $? -ne 0 ]]; then
    echo "Got error in hadd, aborting"
    rm $HADD_BASE/state/${SYSTEMATIC}_${DATASET} 
    rm $HADD_BASE/${SYSTEMATIC}_${DATASET}.root
    touch $HADD_BASE/${SYSTEMATIC}_${DATASET}.FAIL
    echo $DIR/*.root >> $HADD_BASE/${SYSTEMATIC}_${DATASET}.FAIL 
fi

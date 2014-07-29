#!/bin/bash

set -x
source $SUSHYFT_BASE/scripts/functions.sh
declare -f getDatasetEventsFromDAS
CHANGES_FOUND=0
DATASETS_TO_RUN=(  )
while read DATASET; do
# Foreach dataset in _pat.txt
#   pull eventCount from DAS
    # might have to try a couple of times to find the right instance
    echo "event get!"
    DAS_EVENT_COUNT=$(getDatasetEventsFromDAS $DATASET)
    echo "got event!"
    if [ "$DAS_EVENT_COUNT" -lte 0 ]; then
        continue
    fi
    STATE_EVENT_COUNT=$(grep $DATASET $SUSHYFT_STATE_PATH/EDNtuple/inputs.txt | awk '{ print $2 }')
    if [[ "X$DAS_EVENT_COUNT" != "X$STATE_EVENT_COUNT" ]]; then
        echo "Found a changed dataset, time to reprocess it: $DATASET"
        sed -i '/$DATASET/d' $SUSHYFT_STATE_PATH/EDNtuple/inputs.txt
        echo "$DATASET $DAS_EVENT_COUNT" >> $SUSHYFT_STATE_PATH/EDNtuple/inputs.txt
        echo "$(date) $DATASET" >> $SUSHYFT_STATE_PATH/EDNtuple/inProgress.txt
        DATASETS_TO_RUN=( "${DATASETS_TO_RUN[@]}" "$DATASET" )
        CHANGES_FOUND=1
    fi
done <${SUSHYFT_DATASET_INPUT}

if [[ $CHANGES_FOUND -eq 0 ]]; then
    echo "No changes found. Exiting"
    rm -rf $SUSHYFT_STATE_PATH
    exit 0
fi
echo "Attempting to grab lock"
pushd $SUSHYFT_STATE_PATH
git commit -am "Locking EDNtuple"
#git push origin
if [[ $? -ne 0 ]]; then
    echo "Couldn't grab lock, aborting"
    rm -rf $SUSHYFT_STATE_PATH
    exit 1
fi
popd

run=$SUSHYFT_EDNTUPLE_VERSION
# Looks like we were successful. Party hard and fire off the processing
CRAB_BASE=$SUSHYFT_SCRATCH_PATH/edntuple
SUSHYFT_BASE=$SUSHYFT_EDNTUPLE_CMSSW_BASE
if [ ! -d $CRAB_BASE ]; then
    mkdir -p $CRAB_BASE
fi

cp $SUSHYFT_BASE/*.py $CRAB_BASE
for LINE in "${DATASETS_TO_RUN[@]}"; do
    if [[ $LINE =~ "MET" || $LINE =~ "SingleMu" ]]; then
        USE_DATA=" useData=1"
        SHORTNAME=getDatasetShortname ${LINE}
    else
        USE_DATA=" useData=0"
        SHORTNAME=getDatasetShortname ${LINE}
        PUBLINE=$(echo ${LINE} | tr '/' ' ' | awk '{ print $2 }' | perl -pe 's/(meloam-|-[a-zA-Z-0-9]{32})//g')
    fi

    if [[ $LINE =~ QCD ]]; then
        LOOSE_LEPTONS="useLooseMuons=1"
    else
        LOOSE_LEPTONS=""
    fi
    echo "Initializing $LINE jobs to $SHORTNAME"
    CFGFILE="$CRAB_BASE/config_${SHORTNAME}.cfg"
    sed "s!DATASETPATH!${LINE}!" $SUSHYFT_BASE/config/crab_edtuple.cfg > $CFGFILE
    PUBTOTAL="melo_${run}_edntuple_${PUBLINE}"
    echo "Publishing to ${PUBLINE}"
    sed -i "s!WORKDIR!$SUSHYFT_EDNTUPLE_PATH/crab_${run}_${SHORTNAME}!" $CFGFILE
    sed -i "s!OUTPUTDATA!$PUBTOTAL!" $CFGFILE
    sed -i "s!pycfg.*!pycfg_params= $USE_DATA $LOOSE_LEPTONS!" $CFGFILE
    if [[ $LINE =~ StoreResults ]]; then
        sed -i "s!dbs_url.*!!" $CFGFILE
    fi
done
# foreach dataset in prodlist
#   add state/ENDTuple/locks/production_HASH(dataset name)
#
rm -rf $SUSHYFT_STATE_PATH

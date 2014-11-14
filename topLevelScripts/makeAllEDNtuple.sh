#!/bin/bash

set -x
source $SHYFT_BASE/scripts/functions.sh
declare -f getDatasetEventsFromDAS
CHANGES_FOUND=0
DATASETS_TO_RUN=(  )
run=$SHYFT_EDNTUPLE_VERSION
if [ ! -d $SHYFT_STATE_PATH/EDNtuple/ ]; then
    mkdir -p $SHYFT_STATE_PATH/EDNtuple
fi
while read DATASET; do
# Foreach dataset in _pat.txt
#   pull eventCount from DAS
    # might have to try a couple of times to find the right instance
    DAS_LOCATION=$(grep $DATASET $SHYFT_STATE_PATH/EDNtuple/inputs_${run}.txt | tail -n 1 | awk '{print $3}')
    DAS_VALUE=($(getDatasetEventsFromDAS $DATASET $DAS_LOCATION))
    DAS_EVENT_COUNT=${DAS_VALUE[0]}
    if [ "$DAS_EVENT_COUNT" -le 0 ]; then
        continue
    fi
    STATE_EVENT_COUNT=$(grep $DATASET $SHYFT_STATE_PATH/EDNtuple/inputs_${run}.txt | tail -n 1 | awk '{ print $2 }')
    if [[ "X$DAS_EVENT_COUNT" != "X$STATE_EVENT_COUNT" ]]; then
        echo "Found a changed dataset, time to reprocess it: $DATASET"
        sed -i '/$DATASET/d' $SHYFT_STATE_PATH/EDNtuple/inputs_${run}.txt
        echo "$DATASET $DAS_EVENT_COUNT ${DAS_VALUE[1]}" >> $SHYFT_STATE_PATH/EDNtuple/inputs_${run}.txt
        echo "$(date) $DATASET ${DAS_VALUE[1]}" >> $SHYFT_STATE_PATH/EDNtuple/inProgress_${run}.txt
        DATASETS_TO_RUN=( "${DATASETS_TO_RUN[@]}" "$DATASET" )
        CHANGES_FOUND=1
    fi
done <${SHYFT_DATASET_INPUT}

if [[ $CHANGES_FOUND -eq 0 ]]; then
    echo "No changes found. Exiting"
    #rm -rf $SHYFT_STATE_PATH/EDNtuple
    exit 0
fi
#echo "Attempting to grab lock"
#pushd $SHYFT_STATE_PATH/EDNtuple
#git commit -am "Locking EDNtuple"
#git push origin
#if [[ $? -ne 0 ]]; then
#    echo "Couldn't grab lock, aborting"
#    rm -rf $SHYFT_STATE_PATH/EDNtuple
#    exit 1
#fi
#popd

# Looks like we were successful. Party hard and fire off the processing
CRAB_BASE=$SHYFT_SCRATCH_PATH/edntuple
#SHYFT_BASE=$SHYFT_EDNTUPLE_CMSSW_BASE
if [ ! -d $CRAB_BASE ]; then
    mkdir -p $CRAB_BASE
fi

cp $SHYFT_BASE/*.py $CRAB_BASE
for LINE in "${DATASETS_TO_RUN[@]}"; do
    if [[ $LINE =~ "MET" || $LINE =~ "SingleMu" ]]; then
        USE_DATA=" useData=1"
        SHORTNAME=$(getDatasetShortname ${LINE})
    else
        USE_DATA=" useData=0"
        SHORTNAME=$(getDatasetShortname ${LINE})
        PUBLINE=$(echo "_${LINE}" | tr '/' ' ' | awk '{ print $2 }' | perl -pe 's/(meloam-|-[a-zA-Z-0-9]{32})//g')
    fi

    if [[ $LINE =~ QCD ]]; then
        LOOSE_LEPTONS="useLooseMuons=1"
    else
        LOOSE_LEPTONS=""
    fi
    echo "Initializing $LINE jobs to $SHORTNAME"
    CFGFILE="$CRAB_BASE/config_${run}_${SHORTNAME}.cfg"
    sed "s!DATASETPATH!${LINE}!" $SHYFT_BASE/config/crab_edtuple.cfg > $CFGFILE
    PUBTOTAL="melo_${run}_edntuple${PUBLINE}"
    echo "Publishing to ${PUBLINE}"
    sed -i "s!WORKDIR!$SHYFT_EDNTUPLE_PATH/crab_${run}_${SHORTNAME}!" $CFGFILE
    sed -i "s!OUTPUTDATA!$PUBTOTAL!" $CFGFILE
    sed -i "s!pycfg.*!pycfg_params= $USE_DATA $LOOSE_LEPTONS!" $CFGFILE
    INPUT_INSTANCE=$(grep ${LINE} $SHYFT_STATE_PATH/EDNtuple/inputs_${run}.txt | tail -n 1 | awk '{print $3; }')
    sed -i "s!dbs_url.*!dbs_url = ${INPUT_INSTANCE}!" $CFGFILE
done
# foreach dataset in prodlist
#   add state/ENDTuple/locks/production_HASH(dataset name)
#
#rm -rf $SHYFT_STATE_PATH/EDNtuple

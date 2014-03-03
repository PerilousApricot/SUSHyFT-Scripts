#!/bin/bash

CHANGES_FOUND=0
DATASETS_TO_RUN=(  )
while read DATASET; do
# Foreach dataset in _pat.txt
#   pull eventCount from DAS
    # might have to try a couple of times to find the right instance
    for INSTANCE in "" "instance=cms_dbs_ph_analysis_02" "instance=cms_dbs_ph_analysis_03"; do
        if [[ ! $DATASET =~ 'StoreResults' ]]; then
            INSTANCE='instance=cms_dbs_ph_analysis_02'
        fi
        if [[ -n "$(grep $DATASET $STATEDIR/EDNtuple/inProgress.txt)" ]]; then
            continue
        fi
        set -x
        DAS_EVENT_COUNT=$(./das.py --query "dataset=$DATASET $INSTANCE | grep dataset.nevents" | grep -o [0-9]*)
        set +x
        # not exactly sure if this is correct
        if [[ $DAS_EVENT_COUNT -gt 0 ]]; then
            break
        fi
        DAS_EVENT_COUNT=0
    done
    if [[ $DAS_EVENT_COUNT -lte 0 ]]; then
        break
    fi
    STATE_EVENT_COUNT=$(grep $DATASET $STATEDIR/EDNtuple/inputs.txt | awk '{ print $2 }')
    if [[ "X$DAS_EVENT_COUNT" != "X$STATE_EVENT_COUNT" ]]; then
        echo "Found a changed dataset, time to reprocess it: $DATASET"
        sed -i '/$DATASET/d' $STATEDIR/EDNtuple/inputs.txt
        echo "$DATASET $DAS_EVENT_COUNT" >> $STATEDIR/EDNtuple/inputs.txt
        echo "$(date) $DATASET" >> $STATEDIR/EDNtuple/inProgress.txt
        DATASETS_TO_RUN=( "${DATASETS_TO_RUN[@]}" "$DATASET" )
        CHANGES_FOUND=1
    fi
done < $1

if [[ $CHANGES_FOUND -eq 0 ]]; then
    echo "No changes found. Exiting"
    rm -rf $STATEDIR
    exit 0
fi
echo "Attempting to grab lock"
pushd $STATEDIR
git commit -am "Locking EDNtuple"
#git push origin
if [[ $? -ne 0 ]]; then
    echo "Couldn't grab lock, aborting"
    rm -rf $STATEDIR
    exit 1
fi
popd

run='v2'
# Looks like we were successful. Party hard and fire off the processing
CRAB_BASE=/scratch/meloam/auto_edntuple
SUSHYFT_BASE="/home/meloam/analysis/AnalysisTools/cmssw/shyft_edntuple_53xv2/CMSSW_5_3_11/src/Analysis/EDSHyFT/test/SUSHyFT"
cp $SUSHYFT_BASE/*.py $CRAB_BASE
for LINE in "${DATASETS_TO_RUN[@]}"; do
    if [[ $LINE =~ "MET" || $LINE =~ "SingleMu" ]]; then
        USE_DATA=" useData=1"
        SHORTNAME=$(echo ${LINE} | tr '/' ' ' | tr '_' ' ' | awk '{ print $1 $5 $6 }')
    else
        USE_DATA=" useData=0"
        SHORTNAME=$(echo ${LINE} | tr '/' ' ' | awk '{ print $1 "_" $2 }')
        PUBLINE=$(echo ${LINE} | tr '/' ' ' | awk '{ print $2 }' | perl -pe 's/(meloam-|-[a-zA-Z-0-9]{32})//g')
    fi

    if [[ $LINE =~ QCD ]]; then
        LOOSE_LEPTONS="useLooseMuons=1"
    else
        LOOSE_LEPTONS=""
    fi
    echo "Initializing $LINE jobs to $SHORTNAME"
    CFGFILE="$CRAB_BASE/config_${SHORTNAME}.cfg"
    sed "s!DATASETPATH!${LINE}!" $SUSHYFT_BASE/crab_edtuple.cfg > $CFGFILE
    PUBTOTAL="melo_${run}_edntuple_${PUBLINE}"
    echo "Publishing to ${PUBLINE}"
    sed -i "s!WORKDIR!$CRAB_BASE/crab_${run}_${SHORTNAME}!" $CFGFILE
    sed -i "s!OUTPUTDATA!$PUBTOTAL!" $CFGFILE
    sed -i "s!pycfg.*!pycfg_params= $USE_DATA $LOOSE_LEPTONS!" $CFGFILE
    if [[ $LINE =~ StoreResults ]]; then
        sed -i "s!dbs_url.*!!" $CFGFILE
    fi
done
# foreach dataset in prodlist
#   add state/ENDTuple/locks/production_HASH(dataset name)
#
rm -rf $STATEDIR

#!/bin/bash

# To keep the FWLite files as broad as possible, they keep all of the bings
# this script removes/combines unneeded bins
source $SHYFT_BASE/scripts/functions.sh
toProcess=( )
echo "Gathering jobs to process"
[ -d $SHYFT_REBIN_PATH ] || mkdir -p $SHYFT_REBIN_PATH

rebinHists.py --tagCheck --tagMode=${SHYFT_MODE}
if [ $? -ne 0 ]; then
    >&2 echo "ERROR: Update rebinHists.py to include this binning mode"
    exit 1
fi
while read DATASET; do
    SHORTNAME=$(getDatasetShortname $DATASET)
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
        if [[ ! $BASEDIR =~ ${TESTREGEX} ]]; then
            continue
        fi
        DIR=$SHYFT_FWLITE_PATH/$BASEDIR/$OUTNAME
        DATASET_WCRAB=$( echo $DIR | tr '/' ' ' | awk '{ print $(NF-1) }' )
        DATASET=$( echo $DATASET_WCRAB | perl -pe 's|crab_.*?_(.*)|\1|' )
        SYSTEMATIC=$( echo $DIR | tr '/' ' ' | awk '{ print $(NF) }' )
        HADD_INPUT_FILE=$SHYFT_HADD_PATH/${SYSTEMATIC}_${DATASET}.root
        ADDITIONAL_ARGS=""
        if [[ $SHORTNAME == QCD* ]]; then
            ADDITIONAL_ARGS=" --qcd"
        fi
        if [[ $IS_DATA -eq 1 ]]; then
            ADDITIONAL_ARGS="$ADDITIONAL_ARGS --isData"
        fi
        toProcess+=("runIfChanged.sh $SHYFT_REBIN_PATH/${SHYFT_MODE}/${SYSTEMATIC}_${DATASET}.root $HADD_INPUT_FILE `which rebinHists.py` -- rebinHists.py --tagMode=${SHYFT_MODE} --outDir=$SHYFT_REBIN_PATH/${SHYFT_MODE} $ADDITIONAL_ARGS $HADD_INPUT_FILE")
    done < $SHYFT_BASE/config/$SHYFT_MODE/fwliteSystematicsList.txt
done < $SHYFT_BASE/config/$SHYFT_MODE/input_pat.txt
echo "Executing ${#toProcess[@]} jobs"
COMMANDS_TO_UNROLL=10
COMMAND_TO_RUN='sbatch -A jswhep --time=60'
( for ((i = 0; i+$COMMANDS_TO_UNROLL < ${#toProcess[@]}; i += $COMMANDS_TO_UNROLL)); do
    sleep 0.3
    echo "#!/bin/bash
#SBATCH --output=/dev/null
#SBATCH --time=2:00:00
cd /home/meloam
source set-ntuple.sh
unset TERM
$(
for IDX in $(seq $i $(($i + $COMMANDS_TO_UNROLL - 1))); do
    echo "${toProcess[$IDX]}"
done
)" | eval $COMMAND_TO_RUN
done; )
#( for ((i = 0; i < ${#toProcess[@]}; i++)); do
#    echo "${toProcess[$i]}"
#done; )  | parallel -j $SHYFT_QUAD_CORE_COUNT --eta --progress


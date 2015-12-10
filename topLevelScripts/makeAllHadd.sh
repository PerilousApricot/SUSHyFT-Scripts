#!/bin/bash
unset TERM

# hadds all the fwlite files together in a sensible way
source $SHYFT_BASE/scripts/functions.sh
toProcess=( )
toOutput=( )
echo "Gathering jobs to process"
[ -e $SHYFT_BASE/output/$SHYFT_MODE/hadd_missing_input.txt ] && rm $SHYFT_BASE/output/$SHYFT_MODE/hadd_missing_input.txt
[ -e $SHYFT_BASE/output/$SHYFT_MODE/hadd_missing_output.txt ] && rm $SHYFT_BASE/output/$SHYFT_MODE/hadd_missing_output.txt
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
        if [[ ! $BASEDIR =~ $TESTREGEX ]]; then
            continue
        fi
        DIR=$SHYFT_FWLITE_PATH/$BASEDIR/$OUTNAME
        if [[ ! -n "$(find $DIR -maxdepth 1 -name '*.root' -print -quit 2>/dev/null)" ]]; then
            echo $DIR >> $SHYFT_BASE/output/$SHYFT_MODE/hadd_missing_input.txt
            echo "ERROR: Missing hadd inputs for $DIR"
            continue
        fi
        DATASET_WCRAB=$( echo $DIR | tr '/' ' ' | awk '{ print $(NF-1) }' )
        DATASET=$( echo $DATASET_WCRAB | perl -pe 's|crab_.*?_(.*)|\1|' )
        SYSTEMATIC=$( echo $DIR | tr '/' ' ' | awk '{ print $(NF) }' )
        #toProcess+=("rm -f $SHYFT_HADD_PATH/${SYSTEMATIC}_${DATASET}_{edntuple,fwlite}.txt && printIntegrals.py -r $SHYFT_HADD_PATH/${SYSTEMATIC}_${DATASET}.root:^nEvents\$ > $SHYFT_HADD_PATH/${SYSTEMATIC}_${DATASET}_fwlite.txt ; cp $SHYFT_FWLITE_PATH/$BASEDIR/edntuple_events.txt $SHYFT_HADD_PATH/${SYSTEMATIC}_${DATASET}_edntuple.txt")
        toProcess+=("rm -f $SHYFT_HADD_PATH/${SYSTEMATIC}_${DATASET}_{edntuple,fwlite}.txt $SHYFT_HADD_PATH/${SYSTEMATIC}_${DATASET}.root && haddFWLiteFiles.sh $SHYFT_HADD_PATH/${SYSTEMATIC}_${DATASET}.root $DIR/*.root ; printIntegrals.py -r $SHYFT_HADD_PATH/${SYSTEMATIC}_${DATASET}.root:^nEvents\$ > $SHYFT_HADD_PATH/${SYSTEMATIC}_${DATASET}_fwlite.txt ; cp $SHYFT_FWLITE_PATH/$BASEDIR/edntuple_events.txt $SHYFT_HADD_PATH/${SYSTEMATIC}_${DATASET}_edntuple.txt")
        toOutput+=($SHYFT_HADD_PATH/${SYSTEMATIC}_${DATASET}.root)
    done < $SHYFT_BASE/config/$SHYFT_MODE/fwliteSystematicsList.txt
done < $SHYFT_BASE/config/$SHYFT_MODE/input_pat.txt
echo "$toProcess" | grep 15
echo "Executing ${#toProcess[@]} jobs"
COMMANDS_TO_UNROLL=10
COMMAND_TO_RUN='sbatch -A jswhep --time=60'
( for ((i = 0; i < ${#toProcess[@]}; i += $COMMANDS_TO_UNROLL)); do
    sleep 0.3
    echo "#!/bin/bash
#SBATCH --output=/dev/null
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
# Check the files were successfully written
#for ((i = 0; i < ${#toOutput[@]}; i++)); do
#    if [ ! -e "${toOutput[$i]}" ]; then
#        echo ${toOutput[$i]} >> $SHYFT_BASE/output/$SHYFT_MODE/hadd_missing_output.txt
#    fi
#done

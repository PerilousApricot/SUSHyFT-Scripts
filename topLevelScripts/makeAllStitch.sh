#!/bin/bash
if [[ ! -d ${SHYFT_STITCHED_PATH}/${SHYFT_MODE} ]]; then
    mkdir -p ${SHYFT_STITCHED_PATH}/${SHYFT_MODE}
fi
toProcess=( )
payloads=( )
for CFG in $SHYFT_BASE/config/$SHYFT_MODE/stitchSystematicConfigs/*.cfg; do
    COMMAND_TO_RUN="stitch.py ${SHYFT_REBIN_PATH}/${SHYFT_MODE} ${SHYFT_STITCHED_PATH}/${SHYFT_MODE} $SHYFT_BASE/config/$SHYFT_MODE/stitchConfig.cfg"
    OUTPUTS=""
    INPUTS=""
    while read LINE; do
        # not sure how to break this up
        if [[ -z $OUTPUTS ]]; then
            OUTPUTS=$LINE
        else
            INPUTS="$INPUTS $LINE"
        fi
    done < <($COMMAND_TO_RUN $CFG --getInputFiles)
    PAYLOAD="stitch.py ${SHYFT_REBIN_PATH}/${SHYFT_MODE} ${SHYFT_STITCHED_PATH}/${SHYFT_MODE} $SHYFT_BASE/config/$SHYFT_MODE/stitchConfig.cfg $CFG"
    toProcess+=("runIfChanged.sh $OUTPUTS $INPUTS `which stitch.py` $SHYFT_BASE/config/$SHYFT_MODE/stitchConfig.cfg $CFG -- $PAYLOAD")
    payload+=( "$PAYLOAD" )
done
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
      

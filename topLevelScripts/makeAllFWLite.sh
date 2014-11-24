#!/bin/bash

source $SUSHYFT_BASE/scripts/functions.sh

# set the input version
run=$SUSHYFT_EDNTUPLE_VERSION
# Looks like we were successful. Party hard and fire off the processing
CRAB_BASE=$SUSHYFT_FWLITE_PATH
cp $SUSHYFT_EDNTUPLE_CMSSW_BASE/src/Analysis/EDSHyFT/test/SUSHyFT/*.py $CRAB_BASE

SCHEDULER_STATUS=$(qstat | grep `whoami` | grep -e ' R ' -e ' Q ' )
# choose systematics
SYSTEMATICS_SELECTOR=""

declare -A MISSING_FILES

# Pull the state repository
CHANGES_FOUND=0

DATASETS_TO_RUN=(  )

if [[ ! -d $SUSHYFT_FWLITE_PATH ]]; then
    mkdir -p $SUSHYFT_FWLITE_PATH
fi

FWLITE_LOG=$SUSHYFT_BASE/output/$SUSHYFT_MODE/fwlite_summary.txt
if [ -e $FWLITE_LOG ]; then
    rm $FWLITE_LOG
fi
# loop over all the samples
while read DATASET; do
    SHORTNAME=$(getDatasetShortname $DATASET)
    DIR=$SUSHYFT_EDNTUPLE_PATH/crab_${run}_${SHORTNAME}
    DIR_OUT=$DIR
    # I named some directories with a different system, for some dumb reason
    SHORTNAME_BAK=$SHORTNAME
    SHORTNAME_OUT=$SHORTNAME
    for PATTERN in 's/\(.*\)_meloam.*/\1/' 's/\(.*\)_Summer12.*/\1/' 's/\(.*\)_StoreResults.*/\1/' 's/\(.*\)_None.*/\1/' 's/\(.*\)_jdamgov.*/\1/'; do
        if [[ -d $DIR/res ]]; then
            break
        fi
        SHORTNAME=$(echo $SHORTNAME_BAK | sed $PATTERN)
        DIR=$SUSHYFT_EDNTUPLE_PATH/crab_${run}_${SHORTNAME}
        if [[ -d $DIR/res ]]; then
            break
        fi
    done
    if [[ ! -d $DIR/res ]]; then
        echo "CAN'T FIND $SHORTNAME at $DIR"
        echo "$DATASET - Missing EDNTuple" >> $FWLITE_LOG
        continue
    fi
    BASEDIR=$(basename $DIR)
    BASEDIR_OUT=$(basename $DIR_OUT)
    BASEDIR_IN=$(basename $DIR)
    SHORTNAME_IN=$SHORTNAME
    TARGET_DIR=$SUSHYFT_FWLITE_PATH/$BASEDIR_OUT
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
    if [[ $IS_DATA -eq 1 ]]; then
        SAMPLENAME='data'
    else
        case $SHORTNAME in
            Z*)
                SAMPLENAME='zjets'
                ;;
            TTJet*)
                SAMPLENAME='ttjets'
                ;;
            W*)
                SAMPLENAME='wjets'
                ;;
            Tbar*)
                SAMPLENAME='singletop'
                ;;
            T_*)
                SAMPLENAME='singletop'
                ;;
            QCD_*)
                SAMPLENAME='qcd'
                ;;
            G*)
                SAMPLENAME='gjets'
                ;; 
            DY*)
                SAMPLENAME='dyjets'
                ;;
            N1*)
                SAMPLENAME='signal'
                ;;
            *)
                echo "Error, unknown samplename $DIR"
                exit 1
        esac
    fi

    # First, get the list of files to process from CRAB
    # TODO: refactor this so it's a separate script
    # crabhash.txt keeps the hash of the FJR. the file list is in hash-crabhash.txt
    [[ -d $TARGET_DIR ]] || mkdir -p $TARGET_DIR
    CRAB_HASH_POINTER=$TARGET_DIR/crabhash.txt
    if [[ ! -e $CRAB_HASH_POINTER  ]]; then
        OLDCRAB_HASH="unknown"
    else
        OLDCRAB_HASH=$(cat $CRAB_HASH_POINTER)
    fi
    if ! test -n "$(shopt -s nullglob; echo $DIR/res/crab_*.xml)"; then
        echo "No completed jobs found for $DATASET, $DIR"
        echo "$DATASET - No jobs complete" >> $FWLITE_LOG
        continue
    fi
    NEWCRAB_HASH=$(ls -l --time-style=long-iso $DIR/res/crab_fjr*.xml 2>/dev/null | sort | md5sum | awk '{ print $1 }')
    INPUT_MISSING=""
    MISSING_COUNT=0
    # Possibly cache file list
    if [[ $OLDCRAB_HASH != $NEWCRAB_HASH ]]; then
        echo "Hashes don't match, scanning crab dir for info"
        echo "    $OLDCRAB_HASH != $NEWCRAB_HASH"
        # this monstrosity gets the output files from successful FJRs
        CURRENT_INPUT=$( ( for XML in $DIR/res/crab_*.xml;do if [[ $(grep '<FrameworkJobReport Status=\"Success\">' $XML) ]]; then
                            grep '<LFN>' -A 1 $XML | head -n 2 | tail -n 1 | awk '{ print $1 }'
                        fi; done ) | sort | tee $TARGET_DIR/${NEWCRAB_HASH}-crabhash.txt)
        [[ -e $DIR/failed-autofwlite.txt ]] && rm $DIR/failed-autofwlite.txt
        for XML in $DIR/res/crab_*.xml; do
            if [[ ! $(grep '<FrameworkJobReport Status=\"Success\">' $XML) ]]; then
                echo "Failed FJR: $XML" | tee -a $DIR/failed-autofwlite.txt 
            fi
        done
        CURRENT_INPUT_SOURCE=$TARGET_DIR/${NEWCRAB_HASH}-crabhash.txt
        echo "$CURRENT_INPUT" > $CURRENT_INPUT_SOURCE
        echo ${NEWCRAB_HASH} > $CRAB_HASH_POINTER
    else
        # it was already cached
        CURRENT_INPUT_SOURCE=$TARGET_DIR/${OLDCRAB_HASH}-crabhash.txt
        if [[ ! -e $CURRENT_INPUT_SOURCE ]]; then
            rm $CRAB_HASH_POINTER
            echo "Warning: cache was ruined for $CRAB_HASH_POINTER (${OLDCRAB_HASH}). Try again"
            exit 1
        fi
        CURRENT_INPUT=$(cat $CURRENT_INPUT_SOURCE 2>/dev/null)
        echo ${NEWCRAB_HASH} > $CRAB_HASH_POINTER
    fi

    if [[ -z $CURRENT_INPUT ]]; then
        echo "No EDNTuples found for $DIR"
        echo "$DATASET - No jobs succeeded" >> $FWLITE_LOG
        mkdir -p $DIR
        echo "$DATASET" > $DIR/failed-no-ntuple.txt
        continue
    fi

    # Have the input files, compare against what we allegedly processed over
    while read  OUTNAME TESTREGEX SYSTDATA SYSTLINE; do
        echo "Examining output $OUTNAME"
        if [[ $IS_DATA -eq 1 && $SYSTDATA -eq 0 ]]; then
            continue
        fi
        if [[ ! $BASEDIR =~ $TESTREGEX ]]; then
            continue
        fi
        SYSTEMATIC_PATH=$TARGET_DIR/$OUTNAME
        if [[ ! -d $SYSTEMATIC_PATH ]]; then
            echo "--Missing a systematic ($BASEDIR_OUT/$OUTNAME)!"
            mkdir -p $SYSTEMATIC_PATH
            echo -n "" > $SYSTEMATIC_PATH/processed.txt
        elif [[ -z $(ls $SYSTEMATIC_PATH/input_*.txt 2>/dev/null ) ]]; then
            echo "--No input files ($BASEDIR_OUT/$OUTNAME)"
            echo -n "" > $SYSTEMATIC_PATH/processed.txt
        else
            # Attempt to clean out files that have failed
            for SYSTEMATIC_INPUT in $SYSTEMATIC_PATH/input_*.txt; do
                SYSTEMATIC_COUNTER=$(echo -n $SYSTEMATIC_INPUT | sed 's/.*input_\(.*\).txt$/\1/')
                SYSTEMATIC_OUTPUT=$SYSTEMATIC_PATH/output_${SYSTEMATIC_COUNTER}.root
                SYSTEMATIC_STDOUT=$SYSTEMATIC_PATH/stdout_${SYSTEMATIC_COUNTER}.txt
                SYSTEMATIC_MARKER=$SYSTEMATIC_PATH/marker_${SYSTEMATIC_COUNTER}.txt
                SYSTEMATIC_FILE_MISSING=$SYSTEMATIC_PATH/missing_${SYSTEMATIC_COUNTER}.txt
                SYSTEMATIC_FAILED=$SYSTEMATIC_PATH/FAILED.${SYSTEMATIC_COUNTER}
                if [ -e $SYSTEMATIC_FILE_MISSING ]; then
                    SYSTEMATIC_INPUT_CULLED=$SYSTEMATIC_PATH/culled_${SYSTEMATIC_COUNTER}.txt
                    echo "$DATASET - $OUTNAME - Missing Files" >> $FWLITE_LOG
                    awk "{ print \"$DATASET - $OUTNAME - Missing:\" \$0 }" $SYSTEMATIC_FILE_MISSING >> $FWLITE_LOG
                    sort $SYSTEMATIC_INPUT | uniq | sort - $SYSTEMATIC_FILE_MISSING $SYSTEMATIC_FILE_MISSING | uniq -u > $SYSTEMATIC_INPUT_CULLED
                    SYSTEMATIC_INPUT=$SYSTEMATIC_INPUT_CULLED
                fi
                # if there's a root file there, we did a good job
                if [[ -e $SYSTEMATIC_OUTPUT && ! -e $SYSTEMATIC_FAILED ]]; then
                    [ -e $SYSTEMATIC_MARKER ] && rm $SYSTEMATIC_MARKER
                    echo "$DATASET - $OUTNAME - Complete" >> $FWLITE_LOG
                    cat $SYSTEMATIC_INPUT >> $SYSTEMATIC_PATH/processed.txt
                    continue
                fi

                # might still be running
                if [[ -e $SYSTEMATIC_MARKER && "$SCHEDULER_STATUS" == *$(cat $SYSTEMATIC_MARKER)* ]]; then
                    echo "$DATASET - $OUTNAME - Running" >> $FWLITE_LOG
                    cat $SYSTEMATIC_INPUT >> $SYSTEMATIC_PATH/processed.txt
                    continue
                fi
                # beats me, we can probably delete something
                echo "$DATASET - $OUTNAME - Resetting" >> $FWLITE_LOG
                rm -f $SYSTEMATIC_INPUT $SYSTEMATIC_MARKER $SYSTEMATIC_STDOUT $SYSTEMATIC_OUTPUT $SYSTEMATIC_FAILED
            done
        fi
        { rm $SYSTEMATIC_PATH/processed.txt && sort > $SYSTEMATIC_PATH/processed.txt; } < $SYSTEMATIC_PATH/processed.txt
        # compare input and output files to see if we need to either add to fwlite or
        # blow away everything and start over
        if [[ ! -e $CURRENT_INPUT_SOURCE ]]; then
            echo "No input was found, processing it all"
            INPUT_MISSING=$CURRENT_INPUT
            OUTPUT_INVALID=""
        else
            INPUT_MISSING=$( diff -- $SYSTEMATIC_PATH/processed.txt $CURRENT_INPUT_SOURCE  | egrep '^>' | perl -pe 's/^[<>] //' | egrep -v '^$')
            OUTPUT_INVALID=$( diff -- $SYSTEMATIC_PATH/processed.txt $CURRENT_INPUT_SOURCE  | egrep '^<' | perl -pe 's/^[<>] //' | egrep -v '^$')
        fi

        if [[ ! -z $OUTPUT_INVALID ]]; then
            echo "Got an invalid file in the output, blow it all away"
            echo "Resetting $SYSTEMATIC_PATH"
            echo "compare $SYSTEMATIC_PATH/processed.txt $CURRENT_INPUT_SOURCE"
            exit
            rm -rf $SYSTEMATIC_PATH
            mkdir -p $SYSTEMATIC_PATH
            INPUT_MISSING=$CURRENT_INPUT
        fi
        MISSING_COUNT=$( echo -n "$INPUT_MISSING" | wc -l )
        if [[ $MISSING_COUNT -ne 0 ]]; then
            echo "Missing $MISSING_COUNT files in $DIR"
        else
            echo "$DATASET - $OUTNAME All files processed" >> $FWLITE_LOG
            continue
        fi
        # We have no choice but to process some extra things
        # First cull out files that don't exist, this is bad
        echo "$INPUT_MISSING" > $SUSHYFT_FWLITE_PATH/$BASEDIR_OUT/tempinput_pre.txt
        SUBMIT_INPUT=$SUSHYFT_FWLITE_PATH/$BASEDIR_OUT/tempinput.txt
        if [ -e $SUBMIT_INPUT ]; then
            rm $SUBMIT_INPUT
        fi
        while read LINE; do
            if [ -e "/cms/$LINE" ];then
                echo $LINE >> $SUBMIT_INPUT
            else
                echo "$DATASET - $OUTNAME - Replace $LINE" >> $FWLITE_LOG
            fi
        done < $SUSHYFT_FWLITE_PATH/$BASEDIR_OUT/tempinput_pre.txt

        # This script hardcodes set-analysis.sh to find the python files. fix that.
        echo "DOING SUBMIT"
        submit_fwlite_dataset.sh $SUBMIT_INPUT $SYSTEMATIC_PATH $IS_DATA $SAMPLENAME $SYSTLINE
    done < $SUSHYFT_BASE/config/$SUSHYFT_MODE/fwliteSystematicsList.txt
done < $SUSHYFT_BASE/config/$SUSHYFT_MODE/input_pat.txt

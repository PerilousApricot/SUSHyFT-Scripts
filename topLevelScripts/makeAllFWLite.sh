#!/bin/bash

source $SHYFT_BASE/scripts/functions.sh

# set the input version
run=$SHYFT_EDNTUPLE_VERSION
# Looks like we were successful. Party hard and fire off the processing
CRAB_BASE=$SHYFT_FWLITE_PATH
cp $SHYFT_EDNTUPLE_CMSSW_BASE/src/Analysis/EDSHyFT/test/SHyFT/*.py $CRAB_BASE

SCHEDULER_STATUS=$(qstat | grep `whoami` | grep -e ' R ' -e ' Q ' )
# choose systematics
SYSTEMATICS_SELECTOR=""

# Pull the state repository
CHANGES_FOUND=0

DATASETS_TO_RUN=(  )

if [[ ! -d $SHYFT_FWLITE_PATH ]]; then
    mkdir -p $SHYFT_FWLITE_PATH
fi

# loop over all the samples
while read DATASET; do
    SHORTNAME=$(getDatasetShortname $DATASET)
    DIR=$SHYFT_EDNTUPLE_PATH/crab_${run}_${SHORTNAME}
    DIR_OUT=$DIR
    # I named some directories with a different system, for some dumb reason
    SHORTNAME_BAK=$SHORTNAME
    SHORTNAME_OUT=$SHORTNAME
    for PATTERN in 's/\(.*\)_meloam.*/\1/' 's/\(.*\)_Summer12.*/\1/' 's/\(.*\)_StoreResults.*/\1/' 's/\(.*\)_None.*/\1/' 's/\(.*\)_jdamgov.*/\1/'; do
        if [[ -d $DIR/res ]]; then
            break
        fi
        SHORTNAME=$(echo $SHORTNAME_BAK | sed $PATTERN)
        DIR=$SHYFT_EDNTUPLE_PATH/crab_${run}_${SHORTNAME}
        if [[ -d $DIR/res ]]; then
            break
        fi
    done
    if [[ ! -d $DIR/res ]]; then
        echo "CAN'T FIND $SHORTNAME at $DIR"
        continue
    fi
    BASEDIR=$(basename $DIR)
    BASEDIR_OUT=$(basename $DIR_OUT)
    BASEDIR_IN=$(basename $DIR)
    SHORTNAME_IN=$SHORTNAME
    TARGET_DIR=$SHYFT_FWLITE_PATH/$BASEDIR_OUT
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
    [[ -d $TARGET_DIR ]] && mkdir -p $TARGET_DIR
    CRAB_HASH_POINTER=$TARGET_DIR/crabhash.txt
    if [[ ! -e $CRAB_HASH_POINTER  ]]; then
        OLDCRAB_HASH="unknown"
    else
        OLDCRAB_HASH=$(cat $CRAB_HASH_POINTER)
    fi
    if ! test -n "$(shopt -s nullglob; echo $DIR/res/crab_*.xml)"; then
        echo "No completed jobs found for $DATASET, $DIR"
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
        mkdir -p $DIR
        echo "$DATASET" > $DIR/failed-no-ntuple.txt
        continue
    fi

    # Have the input files, compare against what we allegedly processed over
    while read  OUTNAME TESTREGEX SYSTDATA SYSTLINE; do
        if [[ $IS_DATA -eq 1 && $SYSTDATA -eq 0 ]]; then
            continue
        fi
        if [[ ! $BASEDIR =~ "$TESTREGEX" ]]; then
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
                SYSTEMATIC_FAILED=$SYSTEMATIC_PATH/FAILED.${SYSTEMATIC_COUNTER}
                # if there's a root file there, we did a good job
                if [[ -e $SYSTEMATIC_OUTPUT && ! -e $SYSTEMATIC_FAILED ]]; then
                    [ -e $SYSTEMATIC_MARKER ] && rm $SYSTEMATIC_MARKER
                    continue
                fi

                # might still be running
                if [[ -e $SYSTEMATIC_MARKER && "$SCHEDULER_STATUS" == *$(cat $SYSTEMATIC_MARKER)* ]]; then
                    continue
                fi
                # beats me, we can probably delete something
                rm -f $SYSTEMATIC_INPUT $SYSTEMATIC_MARKER $SYSTEMATIC_STDOUT $SYSTEMATIC_OUTPUT $SYSTEMATIC_FAILED
            done
            cat $SYSTEMATIC_PATH/input_*.txt | sort > $SYSTEMATIC_PATH/processed.txt
        fi

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
            continue
        fi
        # We have no choice but to process some extra things
        echo "$INPUT_MISSING" > $SHYFT_FWLITE_PATH/$BASEDIR_OUT/tempinput.txt
        # This script hardcodes set-analysis.sh to find the python files. fix that.
        submit_fwlite_dataset.sh $SHYFT_FWLITE_PATH/$BASEDIR_OUT/tempinput.txt $SYSTEMATIC_PATH $IS_DATA $SAMPLENAME $SYSTLINE
    done < $SHYFT_BASE/config/$SHYFT_MODE/fwliteSystematicsList.txt
done < $SHYFT_BASE/config/$SHYFT_MODE/input_pat.txt

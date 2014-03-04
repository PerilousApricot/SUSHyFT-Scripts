#!/bin/bash

source $SUSHYFT_BASE/scripts/functions.sh

# set the input version
run=$SUSHYFT_EDNTUPLE_VERSION
# Looks like we were successful. Party hard and fire off the processing
CRAB_BASE=$SUSHYFT_FWLITE_PATH
cp $SUSHYFT_EDNTUPLE_CMSSW_BASE/*.py $CRAB_BASE

SCHEDULER_STATUS=$(qstat | grep `whoami` | grep -e ' R ' -e ' Q ' )
# choose systematics
SYSTEMATICS_SELECTOR=""

# Pull the state repository
CHANGES_FOUND=0

DATASETS_TO_RUN=(  )

if [[ ! -d $SUSHYFT_FWLITE_PATH ]]; then
    mkdir -p $SUSHYFT_FWLITE_PATH
fi

# loop over all the samples
while read DATASET; do
    SHORTNAME=$(getDatasetShortname $DATASET)
    echo "Processing $SHORTNAME"
    DIR=$SUSHYFT_EDNTUPLE_PATH/crab_${run}_${SHORTNAME}
    BASEDIR=$(basename $DIR)
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
            *)
                echo "Error, unknown samplename $DIR"
                exit 1
        esac
    fi

    # First, get the list of files to process from CRAB
    # TODO: refactor this so it's a separate script
    echo "Extracting CRAB info"
    # crabhash.txt keeps the hash of the FJR. the file list is in hash-crabhash.txt
    CRAB_HASH_POINTER=$SUSHYFT_FWLITE_PATH/$BASEDIR/crabhash.txt
    OLDCRAB_HASH=$(cat $CRAB_HASH_POINTER)
    NEWCRAB_HASH=$(ls -lah $DIR/res/crab_fjr*.xml 2>/dev/null | sort | md5sum | awk '{ print $1 }')
    INPUT_MISSING=""
    MISSING_COUNT=0
    # Possibly cache file list
    if [[ $OLDCRAB_HASH != $NEWCRAB_HASH ]]; then
        echo "Hashes don't match, scanning crab dir for info"
        # this monstrosity gets the output files from successful FJRs
        CURRENT_INPUT=$( ( for XML in $DIR/res/crab_*.xml;do if [[ $(grep '<FrameworkJobReport Status=\"Success\">' $XML) ]]; then
                            grep '<LFN>' -A 1 $XML | head -n 2 | tail -n 1 | awk '{ print $1 }'
                        fi; done ) | sort | tee $SUSHYFT_FWLITE_PATH/$BASEDIR/${NEWCRAB_HASH}-crabhash.txt)
        [[ -e $DIR/failed-autofwlite.txt ]] && rm $DIR/failed-autofwlite.txt
        for XML in $DIR/res/crab_*.xml; do
            if [[ ! $(grep '<FrameworkJobReport Status=\"Success\">' $XML) ]]; then
                echo "Failed FJR: $XML" | tee -a $DIR/failed-autofwlite.txt 
            fi
        done
        CURRENT_INPUT_SOURCE=$SUSHYFT_FWLITE_PATH/$BASEDIR/${OLDCRAB_HASH}-crabhash.txt
        echo ${NEWCRAB_HASH} > $CRAB_HASH_POINTER
    else
        # it was already cached
        CURRENT_INPUT_SOURCE=$SUSHYFT_FWLITE_PATH/$BASEDIR/${OLDCRAB_HASH}-crabhash.txt
        if [[ ! -e $CURRENT_INPUT_SOURCE ]]; then
            rm $CRAB_HASH_POINTER
            echo "Warning: cache was ruined for $CRAB_HASH_POINTER (${OLDCRAB_HASH}). Try again"
            exit 1
        fi
        CURRENT_INPUT=$(cat $CURRENT_INPUT_SOURCE)
    fi

    if [[ -z $CURRENT_INPUT ]]; then
        echo "No EDNTuples found for $DIR"
        continue
    fi

    # Have the input files, compare against what we allegedly processed over
    echo "Testing for systematics"
    while read  OUTNAME TESTREGEX SYSTDATA SYSTLINE; do
        if [[ $IS_DATA -eq 1 && $SYSTDATA -eq 0 ]]; then
            echo "--Doesn't match because of it needing to be data"
            continue
        fi
        if [[ ! $BASEDIR =~ "$TESTREGEX" ]]; then
            echo "--Doesn't match the regex"
            continue
        fi
        SYSTEMATIC_PATH=$SUSHYFT_FWLITE_PATH/$BASEDIR/$OUTNAME
        if [[ ! -d $SYSTEMATIC_PATH ]]; then
            echo "--Missing a systematic ($SYSTEMATIC_PATH)!"
            mkdir -p $SYSTEMATIC_PATH
            echo "" > $SYSTEMATIC_PATH/processed.txt
        elif [[ -z "ls $SYSTEMATIC_PATH/input_*.txt" ]]; then
            echo "--No input files ($SYSTEMATIC_PATH)"
            echo "" > $SYSTEMATIC_PATH/processed.txt
        else
            # Attempt to clean out files that have failed
            for SYSTEMATIC_INPUT in $SYSTEMATIC_PATH/input_*.txt; do
                SYSTEMATIC_COUNTER=$(echo $SYSTEMATIC_INPUT | sed 's/.*input_\(.*\).txt$/\1/')
                SYSTEMATIC_OUTPUT=$SYSTEMATIC_PATH/output_${SYSTEMATIC_COUNTER}.root
                SYSTEMATIC_STDOUT=$SYSTEMATIC_PATH/stdout_${SYSTEMATIC_COUNTER}.txt
                SYSTEMATIC_MARKER=$SYSTEMATIC_PATH/marker_${SYSTEMATIC_COUNTER}.txt
                # if there's a root file there, we did a good job
                if [[ -e $SYSTEMATIC_OUTPUT ]]; then
                    [ -e $SYSTEMATIC_MARKER ] && rm $SYSTEMATIC_MARKER
                    continue
                fi

                # might still be running
                if [[ -e $SYSTEMATIC_MARKER && "$SCHEDULER_STATUS" == *$(cat $SYSTEMATIC_MARKER)* ]]; then
                    continue
                fi
                # beats me, we can probably delete something
                rm -f $SYSTEMATIC_INPUT $SYSTEMATIC_MARKER $SYSTEMATIC_STDOUT $SYSTEMATIC_OUTPUT
            done
            cat $SYSTEMATIC_PATH/input_*.txt | sort > $SYSTEMATIC_PATH/processed.txt
        fi

        # compare input and output files to see if we need to either add to fwlite or
        # blow away everything and start over
        INPUT_MISSING=$( diff -- $SYSTEMATIC_PATH/processed.txt $CURRENT_INPUT_SOURCE  | egrep '^<' | perl -pe 's/^[<>] //' | egrep -v '^$')
        OUTPUT_INVALID=$( diff -- $SYSTEMATIC_PATH/processed.txt $CURRENT_INPUT_SOURCE  | egrep '^>' | perl -pe 's/^[<>] //' | egrep -v '^$')

        if [[ ! -z $OUTPUT_INVALID ]]; then
            echo "Got an invalid file in the output, blow it all away"
            echo "Resetting $SYSTEMATIC_PATH"
            echo "compare $SYSTEMATIC_PATH/processed.txt $CURRENT_INPUT_SOURCE"
            rm -rf $SYSTEMATIC_PATH
            mkdir -p $SYSTEMATIC_PATH
            INPUT_MISSING=$CURRENT_INPUT
        fi
        MISSING_COUNT=$( echo -n "$INPUT_MISSING" | wc -l )
        if [[ $MISSING_COUNT -ne 0 ]]; then
            echo "Missing $MISSING_COUNT files"
        else
            continue
        fi
        # We have no choice but to process some extra things
        echo "$INPUT_MISSING" > $SUSHYFT_FWLITE_PATH/$BASEDIR/tempinput.txt
        # This script hardcodes set-analysis.sh to find the python files. fix that.
        submit_fwlite_dataset.sh $SUSHYFT_FWLITE_PATH/$BASEDIR/tempinput.txt $SYSTEMATIC_PATH $IS_DATA $SAMPLENAME $SYSTLINE
    done < $SUSHYFT_BASE/config/$SUSHYFT_MODE/fwliteSystematicsList.txt
done < $SUSHYFT_BASE/config/$SUSHYFT_MODE/input_pat.txt

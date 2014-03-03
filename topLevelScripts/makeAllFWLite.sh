#!/bin/bash

# set the input version
EDNTUPLE_VERSION='2'

run='v2'
# Looks like we were successful. Party hard and fire off the processing
CRAB_BASE=/scratch/meloam/auto_fwlite
SUSHYFT_BASE="/home/meloam/analysis/AnalysisTools/cmssw/shyft_edntuple_53xv2/CMSSW_5_3_11/src/Analysis/EDSHyFT/test/SUSHyFT"
cp $SUSHYFT_BASE/*.py $CRAB_BASE

# choose systematics
SYSTEMATICS_SELECTOR=""

# Pull the state repository
CHANGES_FOUND=0

DATASETS_TO_RUN=(  )

if [[ ! -d /scratch/meloam/auto_fwlite ]]; then
    mkdir -p /scratch/meloam/auto_fwlite
fi

# loop over all the samples
for DIR in /scratch/meloam/auto_edntuple/crab_v${EDNTUPLE_VERSION}_{T_,Tbar_,TTJets_Massive,WJetsToLNu_Tune,WJetsToLNu_scale,WJetsToLNu_matching,SingleMuRun,MET,DYJetsToLL_M-50_Tune,QCD_*star_8TeV}*/; do
#for DIR in /scratch/meloam/auto_edntuple/crab_v${EDNTUPLE_VERSION}_T_*/; do
    echo "Processing $DIR"
    BASEDIR=$(basename $DIR)
    case $BASEDIR in
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

    THIS_DATASET_CHANGED=0
    if [[ ! -d /scratch/meloam/auto_fwlite/$BASEDIR || ! "$(ls -A /scratch/meloam/auto_fwlite/$BASEDIR)" || ! -e /scratch/meloam/auto_fwlite/$BASEDIR/processed.txt ]]; then
        mkdir -p /scratch/meloam/auto_fwlite/$BASEDIR
        touch /scratch/meloam/auto_fwlite/$BAEDIR/processed.txt
        CHANGES_FOUND=1
        THIS_DATASET_CHANGED=1
    else
        # if the target dir already exists, see if the job's already running
        # we should be able to tell because we marked down the list of processed files
        COUNTS_MATCH=1
        PROCESSED_FILES=$(wc -l /scratch/meloam/auto_fwlite/$BASEDIR/processed.txt | awk '{ print $1 }')
        for SYSTEMATIC in /scratch/meloam/auto_fwlite/$BASEDIR/*/; do
            INPUT_COUNT=0
            for SYSTEMATIC_INPUT in $SYSTEMATIC/input_*.txt; do
                ONE_COUNT=$(wc -l $SYSTEMATIC_INPUT | awk '{print $1}')
                INPUT_COUNT=$((INPUT_COUNT+ONE_COUNT))
            done
            OUTPUT_COUNT=$(ls $SYSTEMATIC/output_*.root | wc -l)
            if [[ $INPUT_COUNT -ne $OUTPUT_COUNT ]]; then
                COUNTS_MATCH=0
            fi
        done
        if [[ $COUNTS_MATCH -eq 1 ]]; then
            # let the previous run finish before we start
            echo "Jobs haven't completed - $BASEDIR"
            continue
        fi
    fi
    MISSING_SYSTEMATIC=0
    set +x
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
        if [[ ! -d /scratch/meloam/auto_fwlite/$BASEDIR/$OUTNAME ]]; then
            echo "--Missing a systematic!"
            MISSING_SYSTEMATIC=1
            break
        fi
    done < fwliteSystematicsList.txt

    # So there was at least a run before, and it doesn't appear to be currently running
    # and we've checked for any missing systematics. See if the upstream stuff
    # has changed
    echo "Extracting CRAB info"
    OLDCRAB_HASH=$(cat /scratch/meloam/auto_fwlite/$BASEDIR/crabhash.txt)
    NEWCRAB_HASH=$(ls -lah $DIR/res/crab_fjr*.xml | sort | md5sum | awk '{ print $1 }')
    INPUT_MISSING=""
    MISSING_COUNT=0
    if [[ $OLDCRAB_HASH != $NEWCRAB_HASH ]]; then
        echo "Hashes don't match, scanning crab dir for info"
        CURRENT_INPUT=$( ( for XML in $DIR/res/crab_*.xml;do if [[ $(grep '<FrameworkJobReport Status=\"Success\">' $XML) ]]; then
                            grep '<LFN>' -A 1 $XML | head -n 2 | tail -n 1 | awk '{ print $1 }'
                        fi; done ) | sort | tee /scratch/meloam/auto_fwlite/$BASEDIR/processed.txt )
        # blergh, fuck me, I don't know how to make this work
        CURRENT_SUM=$( echo "$CURRENT_INPUT" | md5sum | awk '{ print $1 }' | tee /scratch/meloam/auto_fwlite/$BASEDIR/crabhash.txt)
        INPUT_MISSING=$( echo "$CURRENT_INPUT" | diff -- /scratch/meloam/auto_fwlite/$BASEDIR/processed.txt -  | egrep '^<' | perl -pe 's/^[<>] //' | egrep -v '^$')
        OUTPUT_INVALID=$( echo "$CURRENT_INPUT" | diff -- /scratch/meloam/auto_fwlite/$BASEDIR/processed.txt -  | egrep '^>' | perl -pe 's/^[<>] //' | egrep -v '^$')
        if [[ ! -z $OUTPUT_INVALID ]]; then
            echo "Got an invalid file in the output, blow it all away"
            echo rm -rf /scratch/meloam/auto_fwlite/$BASEDIR
            INPUT_MISSING=$CURRENT_INPUT
            THIS_DATASET_CHANGED=1
        fi
        MISSING_COUNT=$( echo "$INPUT_MISSING" | wc -l )
        if [[ $MISSING_COUNT -ne 0 ]]; then
            echo "Missing $MISSING_COUNT files"
        fi
        echo "$NEWCRAB_HASH" > /scratch/meloam/auto_fwlite/$BASEDIR/crabhash.txt
    fi
    # At this point, we've figured out what needs to be reprocessed
    if [[ ! -z $INPUT_MISSING || $THIS_DATASET_CHANGED -eq 1 ]]; then
        echo "Found a changed dataset, time to reprocess it: $BASEDIR"
        if [[ $MISSING_COUNT -eq 0 ]];then
            echo "Got nothing to process..."
            continue
        fi
    elif [[ $MISSING_SYSTEMATIC -eq 1 ]]; then
        echo "We were missing a systematic, let's process it"
        :
    else
        echo "...unchanged"
        continue
    fi

    # Let's get the party going then..
    # the processed.txt has all the files we want, go through and verify each
    # dataset/systematic has the right files, if not, make th extras
    echo "Initializing $DIR jobs"
    DIR=$(basename $DIR)
    case $DIR in
        crab_*_Single*)
            IS_DATA=1
            ;;
        crab_*_MET*)
            IS_DATA=1
            ;;
        *)
            IS_DATA=0
            ;;
    esac
    if [[ $IS_DATA -eq 1 ]]; then
        SAMPLENAME='data'
    else
        case $DIR in
            crab_v*_Z*)
                SAMPLENAME='zjets'
                ;;
            crab_v*_TTJet*)
                SAMPLENAME='ttjets'
                ;;
            crab_v*_W*)
                SAMPLENAME='wjets'
                ;;
            crab_v*_Tbar*)
                SAMPLENAME='singletop'
                ;;
            crab_v*_T_*)
                SAMPLENAME='singletop'
                ;;
            crab_v*_QCD_*)
                SAMPLENAME='qcd'
                ;;
            crab_v*_G*)
                SAMPLENAME='gjets'
                ;; 
            crab_v*_DY*)
                SAMPLENAME='dyjets'
                ;;
            *)
                echo "Error, unknown samplename $DIR"
                exit 1
        esac
    fi
    while read OUTNAME TESTREGEX SYSTDATA SYSTDIR; do
        if [[ $IS_DATA -eq 1 && $SYSTDATA -eq 0 ]]; then
            continue
        fi
        if [[ ! $DIR =~ "$TESTREGEX" ]]; then
            continue
        fi
        if [[ ! -d /scratch/meloam/auto_fwlite/$DIR/$OUTNAME ]]; then
            mkdir -p /scratch/meloam/auto_fwlite/$DIR/$OUTNAME
        fi
        CURRENT_INPUT=$( cat /scratch/meloam/auto_fwlite/$DIR/$OUTNAME/input_*.txt | sort )
        INPUT_MISSING=$( echo "$CURRENT_INPUT" | diff -- /scratch/meloam/auto_fwlite/$BASEDIR/processed.txt -  | egrep '^<' | perl -pe 's/^[<>] //' | egrep -v '^$')
        OUTPUT_INVALID=$( echo "$CURRENT_INPUT" | diff -- /scratch/meloam/auto_fwlite/$BASEDIR/processed.txt -  | egrep '^>' | perl -pe 's/^[<>] //' | egrep -v '^$')
        if [[ ! -z $OUTPUT_INVALID ]]; then
            echo "Got an invalid file in the output, blow it all away"
            echo rm -rf /scratch/meloam/auto_fwlite/$BASEDIR/$OUTNAME
            INPUT_MISSING=$CURRENT_INPUT
        fi
        if [[ -z $INPUT_MISSING ]]; then
            continue
        fi
        echo "$INPUT_MISSING" > /scratch/meloam/auto_fwlite/$DIR/tempinput.txt
        ./submit_fwlite_dataset.sh /scratch/meloam/auto_fwlite/$DIR/tempinput.txt /scratch/meloam/auto_fwlite/$DIR/$OUTNAME $IS_DATA $SAMPLENAME $SYSTDIR
    done < <( cat fwliteSystematicsList.txt $SYSTEMATICS_SELECTOR )
done

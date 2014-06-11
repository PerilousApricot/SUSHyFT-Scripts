#!/bin/bash

# ››› SUSHyFT - Andrew Melo, on the shoulders of others

# Where are we? (Get right bash magic to autodetect)
SCRIPTPATH="${BASH_SOURCE[0]}"
export SUSHYFT_BASE="$(cd "$(dirname "${SCRIPTPATH}")" ; pwd)"

# Which analysis are we doing? Determines input datasets, binning procedure
if [[ -z "$SUSHYFT_MODE" ]]; then
    export SUSHYFT_MODE="ttbar_notau"
else
    echo "Overriding SUSHYFT_MODE to be $SUSHYFT_MODE"
fi

if [[ $(ls -d $SUSHYFT_BASE/config/$SUSHYFT_MODE | wc -l) -gt 1 ]]; then
    >&2 echo "ERROR: Multiple substrings match the \$SUSHYFT_MODE. This is bad"
    return
fi

if [[ ! -e $SUSHYFT_BASE/config/$SUSHYFT_MODE ]]; then
    >&2 echo "ERROR: Configuration \"${SUSHYFT_MODE}\" not found"
    return
fi

# Where are we storing our output datasets?
SUSHYFT_DATA_BASE=$SUSHYFT_BASE/data
export SUSHYFT_EDNTUPLE_PATH=$SUSHYFT_DATA_BASE/auto_edntuple
export SUSHYFT_FWLITE_PATH=$SUSHYFT_DATA_BASE/auto_fwlite
export SUSHYFT_HADD_PATH=$SUSHYFT_DATA_BASE/auto_hadd
export SUSHYFT_REBIN_PATH=$SUSHYFT_DATA_BASE/auto_rebin
export SUSHYFT_STITCHED_PATH=$SUSHYFT_DATA_BASE/auto_stitched
export SUSHYFT_COPYHIST_PATH=$SUSHYFT_DATA_BASE/auto_copyhist

# What are the input datasets (starting from PAT)
export SUSHYFT_DATASET_INPUT=$SUSHYFT_BASE/config/$SUSHYFT_MODE/input_pat.txt

# Where are we storing the state of processing?
export SUSHYFT_STATE_PATH=$SUSHYFT_BASE/state

# What are the versions of processing we'd like?
export SUSHYFT_EDNTUPLE_VERSION="v2"
export SUSHYFT_EDNTUPLE_CMSSW_BASE="FIXME123"

# Where to put CRAB scratch stuff
export SUSHYFT_SCRATCH_PATH=$SUSHYFT_BASE/scratch

# Set some variables for the number of cores
# this works in linux and OSX
export SUSHYFT_CORE_COUNT=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || sysctl -n hw.ncpu)
# We know some things will be very I/O bound
export SUSHYFT_DOUBLE_CORE_COUNT=$(echo "${SUSHYFT_CORE_COUNT}*2" | bc)

# Convenient for syncing
export SUSHYFT_REMOTE_PATH="vmplogin.accre.vanderbilt.edu:/scratch/meloam/SUSHyFT-Scripts"

# Export some path variables
EXTRA_PATH="$SUSHYFT_BASE/scripts:$SUSHYFT_BASE/bin:$SUSHYFT_BASE/topLevelScripts"
if [[ -d $SUSHYFT_BASE/src/parallel/local/bin ]];then
    EXTRA_PATH="$EXTRA_PATH:$SUSHYFT_BASE/src/parallel/local/bin"
fi

if [[ $PATH != *$EXTRA_PATH* ]]; then
    export PATH=$PATH:$EXTRA_PATH
fi

EXTRA_PYTHONPATH="$SUSHYFT_BASE/python"
if [[ $PYTHONPATH != *$EXTRA_PYTHONPATH* ]]; then
    export PYTHONPATH=$PYTHONPATH:$EXTRA_PYTHONPATH
fi

EXTRA_LD_LIBRARY_PATH="$SUSHYFT_BASE/src/shlib"
if [[ $LD_LIBRARY_PATH != *$EXTRA_LD_LIBRARY_PATH* ]]; then
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$EXTRA_LD_LIBRARY_PATH
fi
if [[ $DYLD_LIBRARY_PATH != *$EXTRA_LD_LIBRARY_PATH* ]]; then
    export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$EXTRA_LD_LIBRARY_PATH
fi


if [[ -z ${CMSSW_BASE} ]]; then
    echo "WARNING: No CMSSW installation was sourced, many things may"
    echo "         fail to function."
fi

if [[ -z ${CRABDIR} ]]; then
    echo "WARNING: No CRAB installation was sourced, many things may"
    echo "         fail to function."
fi

command -v md5sum &>/dev/null
if [[ $? -ne 0 ]]; then
    echo "WARNING: 'md5sum' was not found in $PATH, many things will not"
    echo "         function."
fi

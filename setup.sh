#!/bin/bash

# ››› shyft - Andrew Melo, on the shoulders of others

# Where are we? (Get right bash magic to autodetect)
SCRIPTPATH="${BASH_SOURCE[0]}"
SHYFT_BASE="$(cd "$(dirname "${SCRIPTPATH}")" ; pwd)"

# Which analysis are we doing? Determines input datasets, binning procedure
if [[ -z "$SHYFT_MODE" ]]; then
    >&2 echo "You didn't select a configuration mode, please either export
\$SHYFT_MODE to your desired configuration mode or execute
"
    typedef -f shyft &>/dev/null
    if [ $? -ne 0 ]; then
        >&2 echo "    source ${SHYFT_BASE}/scripts/setMode.sh
        
If you're using the One True Shell (bash), and you plan on only having one 
checkout of shyft, you can use the handy 'shyft' alias by first executing:

    source ${SHYFT_BASE}/scripts/shyft_source.sh

and then executing

    shyft mode

To add the 'shyft' alias to your default profile, source 'shyft_source.sh'
in '~/.bash_profile'. At subsequent logins, you can simply use 'shyft' to
access various helper functions
"
    else
        >&2 echo "    shyft mode"
    fi
    return
fi
export SHYFT_BASE
export SHYFT_MODE

if [[ $(ls -d $SHYFT_BASE/config/${SHYFT_MODE}_ 2>/dev/null | wc -l) -gt 1 ]]; then
    >&2 echo "ERROR: Multiple substrings match the \$SHYFT_MODE. This is bad"
    return
fi

if [[ ! -e $SHYFT_BASE/config/$SHYFT_MODE ]]; then
    >&2 echo "ERROR: Configuration \"${SHYFT_MODE}\" not found"
    return
fi

# What are the input datasets (starting from PAT)
export SHYFT_DATASET_INPUT=$SHYFT_BASE/config/$SHYFT_MODE/input_pat.txt

source ${SHYFT_BASE}/scripts/configDefaults.sh
source ${SHYFT_BASE}/config/${SHYFT_MODE}/config.sh

if [ ! -z "$SHYFT_STATE_PATH" ]; then
    echo "Reconfiguring to new config mode. This should hopefully work."
    return
fi

# Where are we storing our output datasets?
SHYFT_DATA_BASE=$SHYFT_BASE/data
export SHYFT_EDNTUPLE_PATH=$SHYFT_DATA_BASE/auto_edntuple
export SHYFT_FWLITE_PATH=$SHYFT_DATA_BASE/auto_fwlite
export SHYFT_HADD_PATH=$SHYFT_DATA_BASE/auto_hadd
export SHYFT_REBIN_PATH=$SHYFT_DATA_BASE/auto_rebin
export SHYFT_STITCHED_PATH=$SHYFT_DATA_BASE/auto_stitched
export SHYFT_COPYHIST_PATH=$SHYFT_DATA_BASE/auto_copyhist

# Where are we storing the state of processing?
export SHYFT_STATE_PATH=$SHYFT_BASE/state

# What are the versions of processing we'd like?
export SHYFT_EDNTUPLE_VERSION="v7"
export SHYFT_EDNTUPLE_CMSSW_BASE="$SHYFT_BASE/checkouts/analyzer"

# Where to put CRAB scratch stuff
export SHYFT_SCRATCH_PATH=$SHYFT_BASE/scratch

# Set some variables for the number of cores
# this works in linux and OSX
export SHYFT_CORE_COUNT=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || sysctl -n hw.ncpu)
# We know some things will be very I/O bound
export SHYFT_DOUBLE_CORE_COUNT=$(echo "${SHYFT_CORE_COUNT}*2" | bc)

# Convenient for syncing
export SHYFT_REMOTE_PATH="vmplogin.accre.vanderbilt.edu:/scratch/meloam/SUSHyFT-Scripts"

# Export some path variables
EXTRA_PATH="$SHYFT_BASE/scripts:$SHYFT_BASE/bin:$SHYFT_BASE/topLevelScripts"
if [[ -d $SHYFT_BASE/src/parallel/local/bin ]];then
    EXTRA_PATH="$EXTRA_PATH:$SHYFT_BASE/src/parallel/local/bin"
fi

if [[ $PATH != *$EXTRA_PATH* ]]; then
    export PATH=$PATH:$EXTRA_PATH
fi

EXTRA_PYTHONPATH="$SHYFT_BASE/python"
if [[ $PYTHONPATH != *$EXTRA_PYTHONPATH* ]]; then
    export PYTHONPATH=$PYTHONPATH:$EXTRA_PYTHONPATH
fi

EXTRA_LD_LIBRARY_PATH="$SHYFT_BASE/src/shlib"
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

#!/bin/bash

SCRIPTPATH="${BASH_SOURCE[0]}"
HERE="$(cd "$(dirname "${SCRIPTPATH}")" ; pwd)"

function cmsset() {
    for SCRAM_LOCATION in /cvmfs/cms.cern.ch/cmsset_default.sh /opt/cms/cmsset_default.sh; do
        if [[ -e $SCRAM_LOCATION ]]; then
            source $SCRAM_LOCATION
        fi
    done
}

# Initializes checkouts
if [[ -z ${CMS_PATH} ]]; then
    cmsset
    if [[ -z ${CMS_PATH} ]]; then
        echo "ERROR: SCRAM didn't load right"
        exit 1
    fi
fi

# Get the analysis checkout
(
    # In a subshell to not mix environments
    cd $HERE/checkouts
    cmsset
    scramv1 project -n analyzer CMSSW CMSSW_5_3_15
    cd analyzer/src
    eval `scramv1 runtime -sh`
    git cms-init
    git cms-addpkg EgammaAnalysis
)


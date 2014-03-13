#!/bin/bash

# processCRAB2Job.sh <dir>
# given a working dir, do everything needed to retry/resubmit all the jobs
set -x
if [[ -e $1/share/crab.cfg ]]; then
    runIfChanged.sh $1/share/machine.xml $1/res/crab*.xml -- setZeroErrorCode.sh crab -status -get -USER.xml_report=machine.xml -c $1
else
    exit 0
fi
XML_PATH=$1/share/machine.xml


#!/bin/bash

# edmMakePhDThesis was a sham, this is the REAL thing.
set -e
makeAllFWLite.sh
makeAllHadd.sh
makeAllRebin.sh
makeAllStitch.sh
makeAllCopyHist.sh
makeAllLumiCalc.sh
makeAllQCDFits.sh
makeAllFits.sh

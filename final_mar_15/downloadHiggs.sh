#!/bin/bash
source ${SHYFT_BASE}/scripts/functions.sh
set -e
set -o pipefail
# make dirs
mkdir -p higgs_download
find higgs_download -name log.txt | xargs rm
rsync -avh --delete --exclude "higgsCombineTest*.root" login.accre.vanderbilt.edu:/scratch/meloam/SUSHyFT-Scripts/higgs_upload/ higgs_download


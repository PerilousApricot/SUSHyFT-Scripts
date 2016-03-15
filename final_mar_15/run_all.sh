#!/bin/bash

set -eu
set -o pipefail
echo "Stop250 Stop300 Stop350 Stop400 Stop450 Stop500 Stop600" | xargs -P 8 -n1 ./run_mass.sh
#./uploadHiggs.sh
#./downloadHiggs.sh
#./make_limit_plot.sh
#THESIS_PATH="/Users/meloam/Dropbox/thesis/auto_generated/"
#cp brazil_limit.pdf $THESIS_PATH

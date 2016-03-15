#!/bin/bash
mkdir -p cardtest
COUNT=0
while [ -e cardtest/${COUNT}/ ]; do
    COUNT=$(( $COUNT + 1 ))
done
mkdir -p cardtest/${COUNT}/

cp *.sh *.mrf *.config cardtest/${COUNT}/
mkdir -p cardtest/templates/
cp -a templates/copyhist cardtest/templates
set -o pipefail
set -eu
./run_all.sh | tee cardtest/${COUNT}/run.txt &
# ./run_old.sh | tee cardtest/${COUNT}/old.txt &
wait
./uploadHiggs.sh
./downloadHiggs.sh
./make_limit_plot.sh | tee cardtest/${COUNT}/limit.txt
cp brazil_limit.pdf cardtest/${COUNT}/
#./make_limit_plot.sh OLD | tee cardtest/${COUNT}/oldlimit.txt
#cp brazil_limit_OLD.pdf cardtest/${COUNT}/
cp -a higgs_download/ cardtest/${COUNT}/
wait
echo "Cardtest $COUNT complete"
osascript -e "display notification \"Cardtest $COUNT complete\" with title \"Higgs\""

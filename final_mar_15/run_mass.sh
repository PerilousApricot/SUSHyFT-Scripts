#!/bin/bash
source $SHYFT_BASE/scripts/functions.sh
set -eux
MASS=$1
MASSDIR="$1"
OLD=${2-}
OLDSUBST=""
OLDDIR=""
if [ "$OLD" == "OLD" ]; then
    OLDSUBST=";s/st-nominal/st-oldnominal/g;s/auto_generated/old_auto_generated/g"
    OLDDIR="OLD/"
    MASSDIR="OLD/$1"
    export SHYFT_MODE=st-oldnomial
else
    export SHYFT_MODE=st-nominal
fi
mkdir -p masses/$MASSDIR
for FILE in *.sh *.config central.mrf z_diboson_fit.mrf fit_para.py extract_covar.py; do
    sed "s/Stop450/$MASS/g${OLDSUBST}" $FILE > masses/$MASSDIR/${FILE}.tmp
    replace_ifchanged masses/$MASSDIR/${FILE} masses/$MASSDIR/${FILE}.tmp
done
cd masses/$MASSDIR
chmod +x *.sh *.py
echo "Running  masses/$MASSDIR"
./run.sh

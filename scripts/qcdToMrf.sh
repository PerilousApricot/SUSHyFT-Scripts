#!/bin/bash
echo "+ fixParamVal = QCDpre=1.0"
for JET in 1 2 3 4 5; do
    echo "- qcdConstr_${JET}j 0 1 -10.0 10.0 1"
    for BINPATH in ${SHYFT_BASE}/output/${SHYFT_MODE}/qcdfit/raw/*; do
        BINFILE=$(basename $BINPATH)
        BINNAME=$(echo ${BINFILE} |  perl -p -e 's/^_\w*(_\dj_\db_\dt)$/\1/')
        if [[ $BINNAME == _${JET}j_* ]]; then
            NORMALIZATION=$(grep -m 1 QCDpre $BINPATH  | awk '{ print $4 }')
            if [[ -z "$NORMALIZATION" ]]; then
                echo "-- ${BINNAME} : QCDpre : 0.0"
            else
                echo "-- ${BINNAME} : QCDpre : $NORMALIZATION $NORMALIZATION"
            fi
        fi
    done
done
        

#!/bin/bash
echo "# Config to scale QCD with the derived SF"
echo "global"
for JET in 1 2 3 4 5; do
    for BINPATH in ${SHYFT_BASE}/output/${SHYFT_MODE}/qcdfit/raw/*; do
        BINFILE=$(basename $BINPATH)
        BINNAME=$(echo ${BINFILE} |  perl -p -e 's/^_\w*(_\dj_\db_\dt)$/\1/')
        if [[ $BINNAME == _${JET}j_* ]]; then
            NORMALIZATION=$(grep -m 1 QCDpre $BINPATH  | awk '{ print $4 }')
            if [[ -z "$NORMALIZATION" ]]; then
                echo "+ scale QCD_\w*${BINNAME}:0.0"
                echo "+ scale QCDpre_\w*${BINNAME}:0.0"
            else
                echo "+ scale QCD_\w*${BINNAME}:$NORMALIZATION"
                echo "+ scale QCDpre_\w*${BINNAME}:$NORMALIZATION"
            fi
        fi
    done
done

echo "(file)"
echo "+ keep ^(Q|S|T|W|Z|D|N).+[12345]j_[012]b_[012]t"

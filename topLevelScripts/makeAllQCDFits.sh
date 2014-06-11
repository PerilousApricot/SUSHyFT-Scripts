#!/bin/bash

source ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/config.sh

if [ $SUSHYFT_SEPARATE_QCD_FIT -eq 0 ]; then
    exit 0
fi

if [[ ! -d ${SUSHFYT_BASE}/state/${SUSHYFT_MODE} ]]; then
    mkdir -p ${SUSHYFT_BASE}/state/${SUSHYFT_MODE}
fi

# This really really depends on having the proper data lumi set

LUMIFILE=${SUSHYFT_BASE}/state/lumisum_${SUSHYFT_EDNTUPLE_VERSION}_SingleMu.txt
if [[ ${SUSHYFT_MODE} == test_* ]]; then
    LUMIFILE=${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/lumi.txt
fi
if [[ ! -e ${LUMIFILE} ]];then
    echo "You need to run makeAllLumiCalc.sh to get an accurate lumi calculation!"
    exit 1
fi

for TAG in 1 2; do 
    for JET in 5 4 3 2 1; do 
        if [[ $TAG -gt $JET ]]; then
            continue
        fi
        runIfChanged.sh ${SUSHYFT_BASE}/state/${SUSHYFT_MODE}_fit_output_${JET}j_${TAG}t.txt ${SUSHYFT_COPYHIST_PATH}/${SUSHYFT_MODE}_metfit.root `which handleQCDShapeAndNormalization.py` -- stdoutWrapper.sh ${SUSHYFT_BASE}/state/${SUSHYFT_MODE}_fit_output_${JET}j_${TAG}t.txt handleQCDShapeAndNormalization.py --stitched-input=${SUSHYFT_COPYHIST_PATH}/${SUSHYFT_MODE}_metfit.root --var=MET --minTags=$TAG --maxTags=$TAG --minJets=$JET --maxJets=$JET --fit --verbose --pretagMinTags=${TAG} --pretagMaxTags=${TAG} --shapeOutputVar=svm --lumi=$(cat ${LUMIFILE})
    done
done

# this should write to an MRF file, not to stdout

(
echo "# -*- conf -*-"
echo "+ fixParamVal = QCD=1.0"

for TAG in 1 2;do
    for JET in 1 2 3 4 5; do
        if [[ $TAG -eq 2 && $JET -eq 1 ]]; then
            continue
        fi
        echo "#Results for QCD jet bin ${JET} tag ${TAG}"; 
        TAGVAL=`grep -A 9 'INFO:Minization -- RooMinuit::optimizeConst: deactivating const optimization' ${SUSHYFT_BASE}/state/${SUSHYFT_MODE}_fit_output_${JET}j_${TAG}t.txt | grep qcdSF` 
        SF=`echo $TAGVAL | awk '{print \$6}'`
        echo "#$TAGVAL"
        echo "#$SF"
        echo "- qcdConstr_${JET}j_${TAG}t 0 1 0.0 0.0 1"
        echo "-- _svm_${JET}j_${TAG}t           :  QCD: $SF 1.00"
    done
done
) > ${SUSHYFT_BASE}/state/${SUSHYFT_MODE}/qcd.mrf

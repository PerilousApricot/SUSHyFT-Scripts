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

OIFS=$IFS
IFS=""
for DIR in ${SUSHYFT_QCD_JETTAG[@]}; do
    IFS=" "
    read -a ONE_ROW <<< "$DIR"
    JET=${ONE_ROW[0]}
    TAG=${ONE_ROW[1]}
    TAU=${ONE_ROW[2]}
    SHAPE=${ONE_ROW[3]}
    runIfChanged.sh ${SUSHYFT_BASE}/state/${SUSHYFT_MODE}/fit_output_${JET}j_${TAG}t.txt ${SUSHYFT_COPYHIST_PATH}/${SUSHYFT_MODE}/metfit.root `which handleQCDShapeAndNormalization.py` -- stdoutWrapper.sh ${SUSHYFT_BASE}/state/${SUSHYFT_MODE}/fit_output_${JET}j_${TAG}t.txt handleQCDShapeAndNormalization.py --stitched-input=${SUSHYFT_COPYHIST_PATH}/${SUSHYFT_MODE}/metfit.root --var=MET --minTags=$TAG --maxTags=$TAG --minJets=$JET --maxJets=$JET --fit --verbose --pretagMinTags=${TAG} --pretagMaxTags=${TAG} --shapeOutputVar=${SHAPE} --lumi=$(cat ${LUMIFILE})
    IFS=""
done
IFS=$OIFS

# this should write to an MRF file, not to stdout

(
echo "# -*- conf -*-"
echo "+ fixParamVal = QCD=1.0"

OIFS=$IFS
IFS=""
for DIR in ${SUSHYFT_QCD_JETTAG[@]}; do
    IFS=" "
    read -a ONE_ROW <<< "$DIR"
    JET=${ONE_ROW[0]}
    TAG=${ONE_ROW[1]}
    TAU=${ONE_ROW[2]}
    SHAPE=${ONE_ROW[3]}
    echo "#Results for QCD jet bin ${JET} tag ${TAG}"; 
    TAGVAL=`grep -A 9 'INFO:Minization -- RooMinuit::optimizeConst: deactivating const optimization' ${SUSHYFT_BASE}/state/${SUSHYFT_MODE}/fit_output_${JET}j_${TAG}t.txt | grep qcdSF` 
    SF=`echo $TAGVAL | awk '{print \$6}'`
    echo "#$TAGVAL"
    echo "#$SF"
    echo "- qcdConstr_${JET}j_${TAG}t 0 1 0.0 0.0 1"
    echo "-- _${SHAPE}_${JET}j_${TAG}t           :  QCD: $SF 1.00"
    IFS=""
done
IFS=$OIFS
) > ${SUSHYFT_BASE}/state/${SUSHYFT_MODE}/qcd.mrf

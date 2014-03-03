#!/bin/bash
# need to extract this into a format the fitter can eat
for TAG in 1 2; do 
    for JET in 5 4 3 2 1; do 
        if [[ $TAG -gt $JET ]]; then
            continue
        fi
        ( set -x
        python2.6 handleQCDShapeAndNormalization.py --stitched-input=/scratch/meloam/auto_copyhist/central_noMET.root --var=MET --minTags=$TAG --maxTags=$TAG --minJets=$JET --maxJets=$JET --fit --verbose --pretagMinTags=0 --pretagMaxTags=9 > fit_output_${JET}j_${TAG}t.txt 2>&1 )
        echo "one fit"
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
        TAGVAL=`grep -A 9 'INFO:Minization -- RooMinuit::optimizeConst: deactivating const optimization' fit_output_${JET}j_${TAG}t.txt | grep qcdSF` 
        SF=`echo $TAGVAL | awk '{print \$6}'`
        echo "#$TAGVAL"
        echo "#$SF"
        echo "- qcdConstr_${JET}j_${TAG}t 0 1 -10.0 10.0 1"
        echo "-- _svm_${JET}j_${TAG}t           :  QCD: $SF 1.00"
    done
done
) > /scratch/meloam/analysis/SHyFTFitter/multiRegionFitter/polynoids_ttbar_notau/qcd.mrf

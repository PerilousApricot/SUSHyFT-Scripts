#!/bin/bash

# The big kahoona - runs the fits
mkdir -p ${SUSHYFT_BASE}/state/${SUSHYFT_MODE}
# First, get the systematic variations
runIfChanged.sh  ${SUSHYFT_BASE}/state/${SUSHYFT_MODE}/btag_sf.mrf  \
                 `which configFitVariations.py` \
                 ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/fitConfigs/nominal.mrf \
                 ${SUSHYFT_COPYHIST_PATH}/central_{nom,BTag}* -- \
    configFitVariations.py \
        ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/fitConfigs/nominal.mrf \
        --func=pol2 --name=BTag_PF --legend --samples=Top,SingleTop,Wbx,Wcx \
        --writeConfig=${SUSHYFT_BASE}/state/${SUSHYFT_MODE}/btag_sf.mrf:btag,0,1 \
        ${SUSHYFT_COPYHIST_PATH}/central_nominal.root:0 \
        ${SUSHYFT_COPYHIST_PATH}/central_BTag080.root:-2 \
        ${SUSHYFT_COPYHIST_PATH}/central_BTag090.root:-1 \
        ${SUSHYFT_COPYHIST_PATH}/central_BTag110.root:1 \
        ${SUSHYFT_COPYHIST_PATH}/central_BTag120.root:2

runIfChanged.sh  ${SUSHYFT_BASE}/state/${SUSHYFT_MODE}/lftag_sf.mrf  \
                 `which configFitVariations.py` \
                 ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/fitConfigs/nominal.mrf \
                 ${SUSHYFT_COPYHIST_PATH}/central_{nom,LFT}* -- \
    configFitVariations.py \
        ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/fitConfigs/nominal.mrf \
        --func=pol2 --name=LFTag_PF --legend --samples=Wqq \
        --writeConfig=${SUSHYFT_BASE}/state/${SUSHYFT_MODE}/lftag_sf.mrf:lftag,0,1 \
        ${SUSHYFT_COPYHIST_PATH}/central_nominal.root:0 \
        ${SUSHYFT_COPYHIST_PATH}/central_LFTag080.root:-2 \
        ${SUSHYFT_COPYHIST_PATH}/central_LFTag090.root:-1 \
        ${SUSHYFT_COPYHIST_PATH}/central_LFTag110.root:1 \
        ${SUSHYFT_COPYHIST_PATH}/central_LFTag120.root:2

runIfChanged.sh  ${SUSHYFT_BASE}/state/${SUSHYFT_MODE}/jes_sf.mrf  \
                 `which configFitVariations.py` \
                 ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/fitConfigs/nominal.mrf \
                 ${SUSHYFT_COPYHIST_PATH}/central_{nom,JES}* -- \
    configFitVariations.py \
        ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/fitConfigs/nominal.mrf \
        --func=pol2 --name=JES_SF --legend --samples=Top,SingleTop,ZJets,WJets \
        --writeConfig=${SUSHYFT_BASE}/state/${SUSHYFT_MODE}/jes_sf.mrf:jes,0,1 \
        --combineSamples=WJets:Wbx+Wcx+Wqq \
        --combineGroups=2jet:_svm_2j_1t+_svm_2j_2t,3jet:_svm_3j_1t+_svm_3j_2t,4jet:_svm_4j_1t+_svm_4j_2t,5jet:_svm_5j_1t+_svm_5j_2t,1jet:_svm_1j_1t \
        --onlyCombinedGroups \
        ${SUSHYFT_COPYHIST_PATH}/central_nominal.root:0 \
        ${SUSHYFT_COPYHIST_PATH}/central_JES095.root:-1 \
        ${SUSHYFT_COPYHIST_PATH}/central_JES105.root:1 \

runIfChanged.sh  ${SUSHYFT_BASE}/state/${SUSHYFT_MODE}/Q2.mrf  \
                 `which configFitVariations.py` \
                 ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/fitConfigs/pretag.mrf \
                 ${SUSHYFT_COPYHIST_PATH}/central_{nom,wje}* -- \
    configFitVariations.py \
        ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/fitConfigs/nominal.mrf \
        --func=pol2 --name=Q2 --legend --samples=WJets \
        --writeConfig=${SUSHYFT_BASE}/state/${SUSHYFT_MODE}/Q2.mrf:Q2,0,1 \
        --combineGroups=2jet:_svm_2j_1t+_svm_2j_2t,3jet:_svm_3j_1t+_svm_3j_2t,4jet:_svm_4j_1t+_svm_4j_2t,5jet:_svm_5j_1t+_svm_5j_2t,1jet:_svm_1j_1t \
        --combineSamples=WJets:Wbx+Wcx+Wqq \
        --onlyCombinedGroups \
        ${SUSHYFT_COPYHIST_PATH}/central_nominal.root:0 \
        ${SUSHYFT_COPYHIST_PATH}/central_wjetsscaledown.root:-1 \
        ${SUSHYFT_COPYHIST_PATH}/central_wjetsscaleup.root:1 \

# This really really depends on having the proper data lumi set
if [[ ! -e ${SUSHYFT_BASE}/state/lumisum_${SUSHYFT_EDNTUPLE_VERSION}_SingleMu.txt ]];then
    echo "You need to run makeAllLumiCalc.sh to get an accurate lumi calculation!"
    exit 1
fi

multiRegionFitter.exe ${SUSHYFT_BASE}/config/${SUSHYFT_MODE}/fitConfigs/floatall.mrf templateFile=data/auto_copyhist/central_nominal.root fitData=1 output=tagged_both savePlots=1 saveTemplates=1 showCorrelations=1 dominos=1 intlumi=$(cat ${SUSHYFT_BASE}/state/lumisum_${SUSHYFT_EDNTUPLE_VERSION}_SingleMu.txt)

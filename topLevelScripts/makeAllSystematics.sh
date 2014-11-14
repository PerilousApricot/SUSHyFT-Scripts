#!/bin/bash

source ${SHYFT_BASE}/config/${SHYFT_MODE}/config.sh

if [[ -z "${SHYFT_SYST_BTAG_COMBINE}" ]];then
    SHYFT_SYST_BTAG_COMBINE="2jet:_svm_2j_1t+_svm_2j_2t,3jet:_svm_3j_1t+_svm_3j_2t,4jet:_svm_4j_1t+_svm_4j_2t,5jet:_svm_5j_1t+_svm_5j_2t,1jet:_svm_1j_1t"
fi

# The big kahoona - runs the fits
mkdir -p ${SHYFT_BASE}/state/${SHYFT_MODE}
if [ $SHYFT_ENABLE_SYSTEMATICS -ne 0 ]; then
    # First, get the systematic variations
    # -unc=pol2 --name=BTag_PF --legend --samples=Top,SingleTop,Wbx,Wcx \
    runIfChanged.sh  ${SHYFT_BASE}/state/${SHYFT_MODE}/btag_sf.mrf  \
                     `which configFitVariations.py` \
                     ${SHYFT_BASE}/config/${SHYFT_MODE}/fitConfigs/floatall.mrf \
                     ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_{nom,BTag}* -- \
        configFitVariations.py \
            ${SHYFT_BASE}/config/${SHYFT_MODE}/fitConfigs/floatall.mrf \
            --func=pol2 --name=BTag_PF --legend --samples=Top,Wbx,Wcx \
            --writeConfig=${SHYFT_BASE}/state/${SHYFT_MODE}/btag_sf.mrf:btag,0,1 \
            ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_nominal.root:0 \
            ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_BTag090.root:-1 \
            ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_BTag080.root:-2 \
            ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_BTag110.root:1  \
            ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_BTag120.root:2

    if [[ ! ${SHYFT_MODE} == test_* && /bin/false ]];then
        runIfChanged.sh  ${SHYFT_BASE}/state/${SHYFT_MODE}/lftag_sf.mrf  \
                         `which configFitVariations.py` \
                         ${SHYFT_BASE}/config/${SHYFT_MODE}/fitConfigs/nominal.mrf \
                         ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_{nom,LFT}* -- \
            configFitVariations.py \
                ${SHYFT_BASE}/config/${SHYFT_MODE}/fitConfigs/nominal.mrf \
                --func=pol2 --name=LFTag_PF --legend --samples=Wqq \
                --writeConfig=${SHYFT_BASE}/state/${SHYFT_MODE}/lftag_sf.mrf:lftag,0,1 \
                ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_nominal.root:0 \
                ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_LFTag080.root:-2 \
                ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_LFTag090.root:-1 \
                ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_LFTag110.root:1 \
                ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_LFTag120.root:2
        #--func=pol2 --name=JES_SF --legend --samples=Top,SingleTop,ZJets,WJets \
       runIfChanged.sh  ${SHYFT_BASE}/state/${SHYFT_MODE}/jes_sf.mrf  \
                         `which configFitVariations.py` \
                         ${SHYFT_BASE}/config/${SHYFT_MODE}/fitConfigs/nominal.mrf \
                         ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_{nom,JES}* -- \
            configFitVariations.py \
                ${SHYFT_BASE}/config/${SHYFT_MODE}/fitConfigs/nominal.mrf \
                --func=pol2 --name=JES_SF --legend --samples=Top,SingleTop,ZJets,WJets \
                --writeConfig=${SHYFT_BASE}/state/${SHYFT_MODE}/jes_sf.mrf:jes,0,1 \
                --combineSamples=WJets:Wbx+Wcx+Wqq \
                --combineGroups=${SHYFT_SYST_BTAG_COMBINE} \
                --onlyCombinedGroups \
                ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_nominal.root:0 \
                ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_JES095.root:-1 \
                ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_JES105.root:1 \

        runIfChanged.sh  ${SHYFT_BASE}/state/${SHYFT_MODE}/Q2.mrf  \
                         `which configFitVariations.py` \
                         ${SHYFT_BASE}/config/${SHYFT_MODE}/fitConfigs/pretag.mrf \
                         ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_{nom,wje}* -- \
            configFitVariations.py \
                ${SHYFT_BASE}/config/${SHYFT_MODE}/fitConfigs/nominal.mrf \
                --func=pol2 --name=Q2 --legend --samples=WJets \
                --writeConfig=${SHYFT_BASE}/state/${SHYFT_MODE}/Q2.mrf:Q2,0,1 \
                --combineGroups=${SHYFT_SYST_BTAG_COMBINE} \
                --combineSamples=WJets:Wbx+Wcx+Wqq \
                --onlyCombinedGroups \
                ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_nominal.root:0 \
                ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_wjetsscaledown.root:-1 \
                ${SHYFT_COPYHIST_PATH}/${SHYFT_MODE}/central_wjetsscaleup.root:1
    fi
fi



#!/bin/bash
source ${SHYFT_BASE}/scripts/functions.sh
set -eu
if [[ "${HIGGS_NOSCALE:-0}" -ne 0 ]]; then
    EXTRA_HIGGS='noscale'
else
    EXTRA_HIGGS=''
fi
mkdir -p higgs${EXTRA_HIGGS}/
mkdir -p templates/{shifted${EXTRA_HIGGS},nofit${EXTRA_HIGGS},shift_noclean${EXTRA_HIGGS}}

# Produce shifted systematic templates for higgs tool
if is_stale higgs${EXTRA_HIGGS}/postfit_central.mrf background_only.mrf fitout/log_background_only.txt; then
    grep -v -e '_[1234]j_' -e '[1234]_Jet' background_only.mrf > higgs${EXTRA_HIGGS}/postfit_central.mrf.$$.tmp
    awk '/^Fit Results:/{flag=1;next}/^$/{flag=0}flag {print "+ fixParamVal = " $2 "=" $4}' \
        fitout/log_background_only.txt | grep -v 'qcd_[1234]j'  >> higgs${EXTRA_HIGGS}/postfit_central.mrf.$$.tmp
    echo "+ names = Stop450" >> higgs${EXTRA_HIGGS}/postfit_central.mrf.$$.tmp
    echo "+ fixParamVal = Stop450=1.0" >> higgs${EXTRA_HIGGS}/postfit_central.mrf.$$.tmp
    replace_ifchanged higgs${EXTRA_HIGGS}/postfit_central.mrf higgs${EXTRA_HIGGS}/postfit_central.mrf.$$.tmp
fi
grep -v '[1234]j' qcd_sf.mrf > qcd_sfTEST.mrf
grep -v '[1234]j' lftag_sf.mrf > lftag_sfTEST.mrf
grep -v '[1234]j' btag_sf.mrf > btag_sfTEST.mrf
grep -v '[1234]j' jes_sf.mrf > jes_sfTEST.mrf

# Rebin for higgs tool
if is_stale higgs${EXTRA_HIGGS}/rebin_nominal.root rebin_higgs.config templates/nominal/nominal.root; then
    copyHistograms.py rebin_higgs.config higgs${EXTRA_HIGGS}/rebin_nominal.root \
                                file=templates/nominal/nominal.root
fi

SHYFT_VALS=( "jes=0.05" "btag=0.10" "lftag=0.10" )
for SHIFT in "${SHYFT_VALS[@]}"; do
    PARAM=${SHIFT%=*}
    VAL=${SHIFT#*=}
    UP=$(perl -e "print $(grep ${PARAM} higgs${EXTRA_HIGGS}/postfit_central.mrf | tr '=' ' ' |  awk '{print $4}') + ($VAL)")

    DOWN=$(perl -e "print $(grep ${PARAM} higgs${EXTRA_HIGGS}/postfit_central.mrf | tr '=' ' ' |  awk '{print $4}') - ($VAL)")
    if is_stale higgs${EXTRA_HIGGS}/postfit_${PARAM}Up.mrf higgs${EXTRA_HIGGS}/postfit_central.mrf; then
        sed "s/+ fixParamVal = ${PARAM}=.*/+ fixParamVal = ${PARAM}=${UP}/" \
            higgs${EXTRA_HIGGS}/postfit_central.mrf > \
            higgs${EXTRA_HIGGS}/postfit_${PARAM}Up.mrf
    fi
    if is_stale higgs${EXTRA_HIGGS}/postfit_${PARAM}Down.mrf higgs${EXTRA_HIGGS}/postfit_central.mrf; then
        sed "s/+ fixParamVal = ${PARAM}=.*/+ fixParamVal = ${PARAM}=${DOWN}/" \
            higgs${EXTRA_HIGGS}/postfit_central.mrf > \
            higgs${EXTRA_HIGGS}/postfit_${PARAM}Down.mrf
    fi
    for DIR in Up Down; do
        runIfChanged.sh templates/shift_noclean${EXTRA_HIGGS}/${PARAM}${DIR}_lum1.0_templates.root \
                higgs${EXTRA_HIGGS}/postfit_${PARAM}${DIR}.mrf \
                higgs${EXTRA_HIGGS}/rebin_nominal.root \
                qcd_sfTEST.mrf btag_sfTEST.mrf lftag_sfTEST.mrf jes_sfTEST.mrf \
            -- \
            multiRegionFitter.exe higgs${EXTRA_HIGGS}/postfit_${PARAM}${DIR}.mrf \
                templateFile=higgs${EXTRA_HIGGS}/rebin_nominal.root dominos=1 \
                output=templates/shift_noclean${EXTRA_HIGGS}/${PARAM}${DIR} savePlots=1 saveTemplates=1 \
                includefiles=qcd_sfTEST.mrf,btag_sfTEST.mrf,lftag_sfTEST.mrf,jes_sfTEST.mrf \
                showcorrelations=1 fitData=1
        runIfChanged.sh higgs${EXTRA_HIGGS}/input_${PARAM}${DIR}.root \
                        fitout_cleanup.config \
                        templates/shift_noclean${EXTRA_HIGGS}/${PARAM}${DIR}_lum1.0_templates.root \
            -- \
            copyHistograms.py fitout_cleanup.config \
                            file=templates/shift_noclean${EXTRA_HIGGS}/${PARAM}${DIR}_lum1.0_templates.root \
                            higgs${EXTRA_HIGGS}/input_${PARAM}${DIR}.root
    done
done

NOSHYFT_VALS=( "nominal=nominal" "jec090=jecDown" "jec110=jecUp" )
if [[ "$(basename $(dirname $(pwd)))" == "OLD" ]]; then
    :
else
    for PROCESS in "tt" "w"; do
        for SYST in "matching" "scale"; do
            NOSHYFT_VALS+=( "${PROCESS}${SYST}down=${PROCESS}${SYST}Down" )
            NOSHYFT_VALS+=( "${PROCESS}${SYST}up=${PROCESS}${SYST}Up" )
        done
    done
fi
echo "Processing " "${NOSHYFT_VALS[@]}"
mkdir -p templates/{shift_noclean,}
for SHIFT in "${NOSHYFT_VALS[@]}"; do
    PARAM=${SHIFT%=*}
    VAL=${SHIFT#*=}
    if is_stale higgs${EXTRA_HIGGS}/rebin_${PARAM}.root rebin_higgs.config templates/nominal/${PARAM}.root ; then
        copyHistograms.py rebin_higgs.config higgs${EXTRA_HIGGS}/rebin_${PARAM}.root \
                                file=templates/nominal/${PARAM}.root
    fi
    runIfChanged.sh templates/shift_noclean${EXTRA_HIGGS}/${PARAM}_lum1.0_templates.root \
                higgs${EXTRA_HIGGS}/postfit_central.mrf \
                higgs${EXTRA_HIGGS}/rebin_${PARAM}.root \
                qcd_sfTEST.mrf btag_sfTEST.mrf lftag_sfTEST.mrf jes_sfTEST.mrf \
            -- \
            multiRegionFitter.exe higgs${EXTRA_HIGGS}/postfit_central.mrf \
                templateFile=higgs${EXTRA_HIGGS}/rebin_${PARAM}.root dominos=1 \
                output=templates/shift_noclean${EXTRA_HIGGS}/${PARAM} savePlots=1 saveTemplates=1 \
                includefiles=qcd_sfTEST.mrf,btag_sfTEST.mrf,lftag_sfTEST.mrf,jes_sfTEST.mrf \
                showcorrelations=1 fitData=1
    runIfChanged.sh higgs${EXTRA_HIGGS}/input_${VAL}.root \
                    fitout_cleanup.cfg \
                    templates/shift_noclean${EXTRA_HIGGS}/${PARAM}_lum1.0_templates.root \
            -- \
            copyHistograms.py fitout_cleanup.config \
                            file=templates/shift_noclean${EXTRA_HIGGS}/${PARAM}_lum1.0_templates.root \
                            higgs${EXTRA_HIGGS}/input_${VAL}.root
done

echo '# Produce input for higgs combination
global
+ keep .*
+ sub Data||data_obs
(central)
+ keep .*
(jecdown)
+ sub (.*)||\1_jecDown
+ keep .*
(jecup)
+ sub (.*)||\1_jecUp
+ keep .*
(btagdown)
+ sub (.*)||\1_btagDown
+ keep .*
(btagup)
+ sub (.*)||\1_btagUp
+ keep .*
(lftagdown)
+ sub (.*)||\1_lftagDown
+ keep .*
(lftagup)
+ sub (.*)||\1_lftagUp
+ keep .*
(jesdown)
+ sub (.*)||\1_jesDown
+ keep .*
(jesup)
+ sub (.*)||\1_jesUp
+ keep .*' > combine_higgs.config.tmp

if [[ "$(basename $(dirname $(pwd)))" == "OLD" ]]; then
    :
else
    echo '(ttmatchingup)
+ sub (.*)||\1_ttmatchingUp
+ keep .*
(ttmatchingdown)
+ sub (.*)||\1_ttmatchingDown
+ keep .*
(ttscaleup)
+ sub (.*)||\1_ttscaleUp
+ keep .*
(ttscaledown)
+ sub (.*)||\1_ttscaleDown
+ keep .*
(wmatchingup)
+ sub (.*)||\1_wmatchingUp
+ keep .*
(wmatchingdown)
+ sub (.*)||\1_wmatchingDown
+ keep .*
(wscaleup)
+ sub (.*)||\1_wscaleUp
+ keep .*
(wscaledown)
+ sub (.*)||\1_wscaleDown
+ keep .*
' >> combine_higgs.config.tmp
fi
    
replace_ifchanged combine_higgs.config combine_higgs.config.tmp

mkdir -p templates/higgs
if [[ "$(basename $(dirname $(pwd)))" == "OLD" ]]; then
    EXTRA_ARGS=""
else
    EXTRA_ARGS="ttmatchingup=higgs${EXTRA_HIGGS}/input_ttmatchingup.root \
						ttmatchingdown=higgs${EXTRA_HIGGS}/input_ttmatchingdown.root \
						ttscaleup=higgs${EXTRA_HIGGS}/input_ttscaleup.root \
						ttscaledown=higgs${EXTRA_HIGGS}/input_ttscaledown.root \
						wmatchingup=higgs${EXTRA_HIGGS}/input_wmatchingup.root \
						wmatchingdown=higgs${EXTRA_HIGGS}/input_wmatchingdown.root \
						wscaleup=higgs${EXTRA_HIGGS}/input_wscaleup.root \
						wscaledown=higgs${EXTRA_HIGGS}/input_wscaledown.root
    "
fi
if is_stale higgs${EXTRA_HIGGS}/nominal_all.root combine_higgs.config higgs${EXTRA_HIGGS}/input_*.root; then
    copyHistograms.py --verbose combine_higgs.config higgs${EXTRA_HIGGS}/nominal_all.root \
                        central=higgs${EXTRA_HIGGS}/input_nominal.root \
                        jecdown=higgs${EXTRA_HIGGS}/input_jecDown.root \
                        jecup=higgs${EXTRA_HIGGS}/input_jecUp.root \
                        btagup=higgs${EXTRA_HIGGS}/input_btagUp.root \
                        btagdown=higgs${EXTRA_HIGGS}/input_btagDown.root \
                        lftagup=higgs${EXTRA_HIGGS}/input_lftagUp.root \
                        lftagdown=higgs${EXTRA_HIGGS}/input_lftagDown.root \
                        jesup=higgs${EXTRA_HIGGS}/input_jesUp.root $EXTRA_ARGS \
                        jesdown=higgs${EXTRA_HIGGS}/input_jesDown.root
fi

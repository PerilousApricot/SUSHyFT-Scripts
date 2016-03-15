#!/bin/bash
source ${SHYFT_BASE}/scripts/functions.sh
export SHYFT_MODE="st-nominal"
NO_PLOT=0
export FAST_MODE=0
export FORCE_STALE=0
set -eu
set -o pipefail
# make dirs
mkdir -p plots/{input,output} fitout configs templates/{copyhist,scaleqcd,nominal} nofit higgs
THESIS_PATH="/Users/meloam/Dropbox/thesis/auto_generated/Stop450/"
CURRENT_MASS="Stop450"
mkdir -p $THESIS_PATH
ALL_GROUPS=$(sed -n 's/^+ groupNames = .*\(_.*_.j_.b_.t\)/\1/p' central.mrf)
CONFIG_ROOT=${SHYFT_BASE}/config/${SHYFT_MODE}
rm -f higgs_datacard.txt higgs/nominal_all.root

#
# Set up input templates
#
for FILE in ${SHYFT_COPYHIST_PATH}/st-nominal/central_*.root; do
    FILENAME=$(basename $FILE)
    FILENAME_NOEXT=$(basename $FILENAME .root)
    rsync -t -c ${FILE} templates/copyhist/${FILENAME}
done

# Apply QCD contribution from outputQCD2.sh
for FILE in templates/copyhist/*.root; do
    FILENAME=$(basename $FILE)
    runIfChanged.sh templates/scaleqcd/${FILENAME} \
                    $CONFIG_ROOT/scale_qcd.config \
                    $FILE \
                    $(which apply_qcd_prescription.sh) \
            -- apply_qcd_prescription.sh $FILE templates/scaleqcd/${FILENAME}
done

# Rebin our nominal templates
if [[ $FAST_MODE -eq 0 ]]; then
    POS='btag|lftag|jes|jec|nominal|ttmatchingdown|ttmatchingup|ttscaledown|ttscaleup|wmatchingdown|wmatchingup|wscaledown|wscaleup'
else
    POS='nominal'
fi
multi.pl --match templates/scaleqcd/central_%.root \
         --pos $POS 1 \
         runIfChanged.sh templates/prenominal/%.root \
                         rebin_central.config \
                         templates/scaleqcd/central_%.root \
         -- \
         copyHistograms.py rebin_central.config templates/prenominal/%.root \
            file=templates/scaleqcd/central_%.root

multi.pl --match templates/prenominal/%.root \
         --pos $POS 1 \
         runIfChanged.sh templates/nominal/%.root \
                         rebin_central2.config \
                         templates/prenominal/%.root \
         -- \
         copyHistograms.py rebin_central2.config templates/nominal/%.root \
            file=templates/prenominal/%.root

rsync -t -c  templates/nominal/nominal.root nominal.root

#
# Do multilepton sideband fit
#

# Make template for multilepton fit
if is_stale templates/z_diboson.root z_diboson_copy.config templates/copyhist/central_nominal.root; then
    copyHistograms.py z_diboson_copy.config templates/z_diboson.root \
                  file=templates/copyhist/central_nominal.root
    fast_plot templates/z_diboson.root plots/input/z_diboson/
fi

# Fit data
if is_stale fitout/log_z_diboson.txt templates/z_diboson.root z_diboson_fit.mrf; then
    multiRegionFitter.exe z_diboson_fit.mrf templateFile=templates/z_diboson.root  \
        output=fitout/z_diboson savePlots=1 saveTemplates=1 \
        showcorrelations=1 fitData=1 dominos=1 \
        | tee fitout/log_z_diboson.txt
fi

# Extract values from fit
DIBOSON_UNC=$(grep -A 6 '^Fit Results' fitout/log_z_diboson.txt | grep 'DiBoson' | awk '{ print $9 }')
ZJET_UNC=$(grep -A 6 '^Fit Results' fitout/log_z_diboson.txt | grep 'ZJets' | awk '{ print $9 }')
DIBOSON_CENTRAL=$(grep -A 6 '^Fit Results' fitout/log_z_diboson.txt | grep 'DiBoson' | awk '{ print $4 }')
ZJET_CENTRAL=$(grep -A 6 '^Fit Results' fitout/log_z_diboson.txt | grep 'ZJets' | awk '{ print $4 }')
cat <<EOF > z_diboson_constr.mrf.$$.tmp
+ constraintNames = ZJets, DiBoson
+ constraintValues = $(perl -e "print 2 * $ZJET_UNC"), $(perl -e "print 2 * $DIBOSON_UNC")
+ rangeNames = DiBoson
+ lowerrange = $(perl -e "print $DIBOSON_CENTRAL - (1.5 * $DIBOSON_UNC)")
+ upperrange = $(perl -e "print $DIBOSON_CENTRAL + (1.5 * $DIBOSON_UNC)")
+ steprange = 0.0001
EOF
#cat <<EOF > z_diboson_constr.mrf.$$.tmp
#+ constraintNames = ZJets, DiBoson
#+ constraintValues = $(perl -e "print 1 * $ZJET_UNC"), $(perl -e "print 1 * $DIBOSON_UNC")
#+ rangeNames = DiBoson
#+ lowerrange = $(perl -e "print $DIBOSON_CENTRAL - (1.0 * $DIBOSON_UNC)")
#+ upperrange = $(perl -e "print $DIBOSON_CENTRAL + (1.0 * $DIBOSON_UNC)")
#+ steprange = 0.0001
#EOF
replace_ifchanged z_diboson_constr.mrf z_diboson_constr.mrf.$$.tmp

# Set default values for fit
cat <<EOF > z_diboson_def.mrf.$$.tmp
+ defaultNames = ZJets, DiBoson
+ defaultValues = $ZJET_CENTRAL, $DIBOSON_CENTRAL
EOF
replace_ifchanged z_diboson_def.mrf z_diboson_def.mrf.$$.tmp

#
# Prepare auxiliary fit configuration files
#

# Teach fitter how to vary QCD
cat <<EOF > qcd_sf.mrf.$$.tmp
+ fixParamVal = QCD=1.0
$(
for JET in 1j 2j 3j 4j 5j; do
    echo "- qcd_${JET} 0 0.1 -1.5 1.5 0.01"
    echo "-- $(echo "$ALL_GROUPS" | grep _${JET}_ | tr '\n' ' ') : QCD : 1.0 1.0"
done
)
EOF
replace_ifchanged qcd_sf.mrf qcd_sf.mrf.$$.tmp

cat <<EOF > fatqcd_sf.mrf.$$.tmp
+ constraintNames = QCD
+ constraintValues = 1.0
+ rangeNames = QCD                                                    
+ lowerrange = 0         
+ upperrange = 10
+ steprange = 0.0001
EOF
replace_ifchanged fatqcd_sf.mrf fatqcd_sf.mrf.$$.tmp

# Teach fitter about our default SM constraints
cat <<EOF > sm_constr.mrf.$$.tmp
+ constraintNames = Top, WJets, SingleTop
+ constraintValues = 0.1, 0.1, 0.2
#+ rangeNames = Stop450                                                            
#+ lowerrange = 0         
#+ upperrange = 1000000  
#+ steprange = 0.0001
EOF
replace_ifchanged sm_constr.mrf sm_constr.mrf.$$.tmp

#
# Compute btag/lftag/JES systematics to produce polynoids
#
function calc_btag_sys() {
    ONEARG=${1#*:}
    NAME=${1%:*}
    if is_stale btag${NAME}_sf.mrf templates/scaleqcd/central_{btag*,nominal}.root central.mrf; then
        configFitVariations.py central.mrf --func=pol2 --legend --samples=WJets,Top,ZJets,SingleTop,DiBoson,Stop450 --name BTag${NAME} \
                --Xrange=0.25 --Ymax=3.0 --Ymin=0.0 \
                --writeConfig=btag${NAME}_sf.mrf:btag,0,0.1 \
                templates/scaleqcd/central_btag080.root:-0.2 \
                templates/scaleqcd/central_btag090.root:-0.1 \
                templates/scaleqcd/central_nominal.root:0 \
                templates/scaleqcd/central_btag110.root:0.1 \
                templates/scaleqcd/central_btag120.root:0.2 \
                --pdf $ONEARG > fitout/log_btag_configfitvariations${NAME}.txt
    fi

    if is_stale lftag${NAME}_sf.mrf templates/scaleqcd/central_{lftag*,nominal}.root central.mrf; then
        configFitVariations.py central.mrf --func=pol2 --legend --samples=WJets,Top,ZJets,SingleTop,DiBoson,Stop450 --name LFTag${NAME} \
                --Xrange=0.25 --Ymax=1.4 --Ymin=0.8 \
                --writeConfig=lftag${NAME}_sf.mrf:lftag,0,0.1 \
                templates/scaleqcd/central_lftag080.root:-0.2 \
                templates/scaleqcd/central_lftag090.root:-0.1 \
                templates/scaleqcd/central_nominal.root:0 \
                templates/scaleqcd/central_lftag110.root:0.1 \
                templates/scaleqcd/central_lftag120.root:0.2 \
                --pdf $ONEARG > fitout/log_lftag_configfitvariations${NAME}.txt
    fi
}
calc_btag_sys ""

if is_stale jes_sf.mrf templates/scaleqcd/central_{jes*,nominal}.root central.mrf; then
    configFitVariations.py central.mrf --func=pol3 --legend --samples=WJets,Top,ZJets,SingleTop,DiBoson,Stop450 --name JES \
        --writeConfig=jes_sf.mrf:jes,0,0.05 \
        --Xrange=0.15 --Ymax=2.5 --Ymin=0.5 \
        --Xaxis="JES Scale Factor" \
        templates/scaleqcd/central_jes090.root:-0.10 \
        templates/scaleqcd/central_jes095.root:-0.05 \
        templates/scaleqcd/central_jes097.root:-0.025 \
        templates/scaleqcd/central_nominal.root:0 \
        templates/scaleqcd/central_jes102.root:0.025 \
        templates/scaleqcd/central_jes105.root:0.05 \
        templates/scaleqcd/central_jes110.root:0.10 \
        --onlyCombinedGroups \
        --combineGroups=1-Jet:_wMT_1j_0b_0t+_wMT_1j_1b_0t+_wMT_1j_0b_1t \
        --combineGroups=2-Jet:_wMT_2j_0b_0t+_wMT_2j_1b_0t+_wMT_2j_0b_1t+_wMT_2j_1b_1t+_wMT_2j_2b_0t \
        --combineGroups=3-Jet:_wMT_3j_0b_0t+_wMT_3j_1b_0t+_wMT_3j_0b_1t+_wMT_3j_1b_1t+_wMT_3j_2b_1t+_wMT_3j_2b_0t \
        --combineGroups=4-Jet:_sumEt_4j_0b_0t+_sumEt_4j_1b_0t+_sumEt_4j_0b_1t+_sumEt_4j_1b_1t+_sumEt_4j_2b_1t+_sumEt_4j_2b_0t \
        --combineGroups=5-Jet:_sumEt_5j_0b_0t+_sumEt_5j_1b_0t+_sumEt_5j_0b_1t+_sumEt_5j_1b_1t+_sumEt_5j_2b_1t+_sumEt_5j_2b_0t \
        --pdf > fitout/log_jes_configfitvariations.txt
fi


#
# Do actual fits
#

# Central fit - no systematics
if is_stale fitout/nosyst_lum1.0_templates.root nominal.root z_diboson_constr.mrf z_diboson_def.mrf qcd_sf.mrf sm_constr.mrf central.mrf; then
    multiRegionFitter.exe central.mrf \
        templateFile=nominal.root \
        output=fitout/nosyst savePlots=1 saveTemplates=1 \
        includefiles=z_diboson_constr.mrf,z_diboson_def.mrf,qcd_sf.mrf \
        includefiles=sm_constr.mrf \
        showcorrelations=1 fitData=1 | tee fitout/log_nosyst.txt
fi

# Central fit - all systematics
if is_stale fitout/central_lum1.0_templates.root nominal.root z_diboson_constr.mrf z_diboson_def.mrf qcd_sf.mrf sm_constr.mrf lftag_sf.mrf jes_sf.mrf btag_sf.mrf central.mrf; then
        multiRegionFitter.exe central.mrf \
        templateFile=nominal.root \
        output=fitout/central savePlots=1 saveTemplates=1 \
        includefiles=z_diboson_constr.mrf,z_diboson_def.mrf,qcd_sf.mrf \
        includefiles=sm_constr.mrf,btag_sf.mrf,lftag_sf.mrf,jes_sf.mrf \
        showcorrelations=1 fitData=1 dominos=1 | tee fitout/log_central.txt
fi

# Central fit - no systematics-fatqcd
#if is_stale fitout/nosystfatqcd_lum1.0_templates.root nominal.root z_diboson_constr.mrf z_diboson_def.mrf fatqcd_sf.mrf sm_constr.mrf central.mrf; then
#    multiRegionFitter.exe central.mrf \
#        templateFile=nominal.root \
#        output=fitout/nosystfatqcd savePlots=1 saveTemplates=1 \
#        includefiles=z_diboson_constr.mrf,z_diboson_def.mrf,fatqcd_sf.mrf \
#        includefiles=sm_constr.mrf \
#        showcorrelations=1 fitData=1 | tee fitout/log_nosystfatqcd.txt
#fi
#
## Central fit - all systematics-fatqcd
#if is_stale fitout/centralfatqcd_lum1.0_templates.root nominal.root z_diboson_constr.mrf z_diboson_def.mrf fatqcd_sf.mrf sm_constr.mrf lftag_sf.mrf jes_sf.mrf btag_sf.mrf central.mrf; then
#        multiRegionFitter.exe central.mrf \
#        templateFile=nominal.root \
#        output=fitout/centralfatqcd savePlots=1 saveTemplates=1 \
#        includefiles=z_diboson_constr.mrf,z_diboson_def.mrf,fatqcd_sf.mrf \
#        includefiles=sm_constr.mrf,btag_sf.mrf,lftag_sf.mrf,jes_sf.mrf \
#        showcorrelations=1 fitData=1 | tee fitout/log_centralfatqcd.txt
#fi

./make_shifted_systematics.sh
if [ $? -ne 0 ]; then
    rm higgs/*
    exit 1
fi
#HIGGS_NOSCALE=1 ./make_shifted_systematics.sh
#if [ $? -ne 0 ]; then
#    rm higgsnoscale/*
#fi

# Central fit - scan likelihoods
DISTS=$(grep -A 16 '^Fit Results' fitout/log_central.txt | awk '{ print $2 }' | sort | uniq)
STOP_CENTRAL=$(grep -A 6 '^Fit Results' fitout/log_central.txt | grep 'Stop450' | awk '{ print $4 }')
STOP_UNC=$(grep -A 6 '^Fit Results' fitout/log_central.txt | grep 'Stop450' | awk '{ print $6 }')
STOP_EVENTS=$(printIntegrals.py -r fitout/central_lum1.0_templates.root:Stop450_update | xargs printf '%0.2f')
STOP_EVENTS_UNC=$(perl -e "print $STOP_EVENTS / $STOP_CENTRAL * $STOP_UNC" | xargs printf '%0.2f')
echo $STOP_CENTRAL > $THESIS_PATH/stop_central.txt
echo $STOP_UNC > $THESIS_PATH/stop_unc.txt
echo $STOP_EVENTS > $THESIS_PATH/stop_events.txt
echo $STOP_EVENTS_UNC > $THESIS_PATH/stop_events_unc.txt
SCAN_CMD="scanvariables=Stop450:-${STOP_CENTRAL}:${STOP_CENTRAL}:12"


echo "**** Not running scan"
if [ 1 -eq 0 ]; then
if [[ $FAST_MODE -eq 0 ]] && is_stale fitout/scan_lum1.0_templates.root nominal.root z_diboson_constr.mrf z_diboson_def.mrf qcd_sf.mrf sm_constr.mrf fitout/log_central.txt fitout/central_lum1.0_templates.root; then
    multiRegionFitter.exe central.mrf \
        templateFile=nominal.root \
        output=fitout/scan savePlots=1 saveTemplates=1 \
        includefiles=z_diboson_constr.mrf,z_diboson_def.mrf,qcd_sf.mrf \
        includefiles=sm_constr.mrf,btag_sf.mrf,lftag_sf.mrf,jes_sf.mrf \
        showcorrelations=1 fitData=1 \
        ${SCAN_CMD} | tee fitout/log_scan.txt
fi
multi.pl cp scan_%.png central_scan_%.png 
fi
#
# Dump plots and tables
#

# Inputs
if is_stale plots/input/central/index.html nominal.root; then
    makeShortInputTable.sh nominal.root > $THESIS_PATH/input_central.tex
    fast_plot nominal.root plots/input/central/
fi
# Systematics
BTAG_ARGS=("_1Jet:--groups=_wMT_1j_0b_0t,_wMT_1j_1b_0t,_wMT_1j_0b_1t"
    "_2Jet:--groups=_wMT_2j_0b_0t,_wMT_2j_1b_0t,_wMT_2j_0b_1t,_wMT_2j_1b_1t,_wMT_2j_2b_0t"
    "_3Jet:--groups=_wMT_3j_0b_0t,_wMT_3j_1b_0t,_wMT_3j_0b_1t,_wMT_3j_1b_1t,_wMT_3j_2b_0t,_wMT_3j_2b_1t"
    "_4Jet:--groups=_sumEt_4j_0b_0t,_sumEt_4j_1b_0t,_sumEt_4j_0b_1t,_sumEt_4j_1b_1t,_sumEt_4j_2b_0t,_sumEt_4j_2b_1t"
    "_5Jet:--groups=_sumEt_5j_0b_0t,_sumEt_5j_1b_0t,_sumEt_5j_0b_1t,_sumEt_5j_1b_1t,_sumEt_5j_2b_0t,_sumEt_5j_2b_1t"
    )
if [[ ${FAST_MODE:-} -eq 0 && ${NO_PLOT:-0} -eq 0 ]]; then
    for ARG in "${BTAG_ARGS[@]}"; do
        calc_btag_sys "$ARG"
    done
    multi.pl cp %_JES.pdf $THESIS_PATH/%_JES.pdf
    multi.pl cp %_BTag_%%.pdf $THESIS_PATH/%_%%_BTAG.pdf 
    multi.pl cp %_LFTag_%%.pdf $THESIS_PATH/%_%%_LFTAG.pdf
fi

# Fit results
mkdir -p plots/output/{central,z_diboson}
if is_stale $THESIS_PATH/jetrow_pretty_includes.tex fitout/central_lum1.0_templates.root; then
    ./extract_central_fit.sh
    plotFit.py fitout/central_lum1.0 plots/output/central/fit
    plotFit.py fitout/z_diboson_lum1.0 plots/output/z_diboson/fit
fi
if is_stale $THESIS_PATH/fit_central_factors.tex fitout/log_central.txt; then
    fitToTex.py --fit fitout/log_central.txt > $THESIS_PATH/fit_central_factors.tex
fi
if is_stale $THESIS_PATH/fit_central_correlation.tex fitout/log_central.txt; then
    fitToTex.py --correlation fitout/log_central.txt > $THESIS_PATH/fit_central_correlation.tex
    #./extract_scan.sh
    #./make_datacard.sh
    #./jan26.sh
fi
# ./mar6.sh
./make_datacard.sh
if [ $? -ne 0 ]; then
    rm -f higgs_datacard.txt
    exit 1
fi
#HIGGS_NOSCALE=1 ./make_datacard.sh
if [ "Stop450" == "St""op450" ]; then
    rsync -a -r -n -t -c "$THESIS_PATH/" "$(dirname $THESIS_PATH)/"
fi

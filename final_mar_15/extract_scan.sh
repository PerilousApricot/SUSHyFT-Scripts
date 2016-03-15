#!/bin/bash
source ${SHYFT_BASE}/scripts/functions.sh
THESIS_PATH="/Users/meloam/Dropbox/thesis/auto_generated/Stop450/"
set -eux
if [[ "${FAST_MODE:-0}" -eq 0 ]]; then
    echo "Skipping scan"
    exit 0
fi

if is_stale fitout/central_scan_Stop450.png central.mrf nominal.root qcd_sf.mrf jes_sf.mrf btag_sf.mrf lftag_sf.mrf z_diboson_constr.mrf sm_constr.mrf z_diboson_def.mrf ; then
    multiRegionFitter.exe central.mrf \
        templateFile=nominal.root \
        output=fitout/extract savePlots=1 saveTemplates=1 \
        showcorrelations=1 fitData=1 \
        includefiles=qcd_sf.mrf,jes_sf.mrf,btag_sf.mrf,lftag_sf.mrf,z_diboson_constr.mrf \
        includefiles=sm_constr.mrf,z_diboson_def.mrf \
        dominos=1 \
        scanvariables=Stop450:-1.4:4.0:24 | tee fitout/log_extract.txt
        mv scan_Stop450.png fitout/central_scan_Stop450.png
fi

grep -A5000 -m1 'scanning Stop450' fitout/log_extract.txt 
grep 'scanning Stop450' -A500 fitout/log_extract.txt | egrep -e '^\s*\d+)' | awk '{print $2 $3}' | sed 's/\[(\(.*\))/\1/' | tr ',' ' ' > fitout/scan_extract.txt
./fitpara.py fitout/scan_extract.txt | tee fitout/scan_parabola.txt
cp fitout/central_scan_* $THESIS_PATH/
exit

sed '/Stop450/d' *_sf.mrf > sf_null.mrf
echo multiRegionFitter.exe null.mrf \
    templateFile=combined_wjets_central_nominal.root \
    output=fitout/null savePlots=1 saveTemplates=1 \
    showcorrelations=1 fitData=1 \
    includefiles=sf_null.mrf,z_diboson_constr.mrf \
    includefiles=sm_constr.mrf,z_diboson_def.mrf \
    print=1 dominos=1



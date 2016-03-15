#!/bin/bash
source ${SHYFT_BASE}/scripts/functions.sh
source functions.sh
set -eux
THESIS_PATH="/Users/meloam/Dropbox/thesis/auto_generated/Stop450/"

if is_stale templates/postqcd.root rebin_central.config templates/copyhist/central_nominal.root; then
    copyHistograms.py rebin_central.config templates/preqcd.root \
                    file=templates/copyhist/central_nominal.root
    copyHistograms.py rebin_central.config templates/postqcd.root \
                    file=templates/scaleqcd/central_nominal.root
fi
fast_plot ${SHYFT_COPYHIST_PATH}/st-nominal/central_nominal.root plots/input/copyhist/
fast_plot ${SHYFT_BASE}/scratch/st-nominal/QCD/qcdfit_step2.root plots/input/qcd_step2/
fast_plot ${SHYFT_BASE}/scratch/st-nominal/QCD/qcdfit_step3.root plots/input/qcd_step3/
fast_plot ${SHYFT_BASE}/scratch/st-nominal/QCD/qcdfit_input.root plots/input/qcd_input/
fast_plot templates/scaleqcd/central_nominal.root plots/input/qcd_scale/
fast_plot ${SHYFT_COPYHIST_PATH}/st-nominal/central_qcdMode.root plots/input/qcd_step1/
fast_plot templates/preqcd.root plots/input/preqcd/
fast_plot templates/postqcd.root plots/input/postqcd/
fast_plot templates/copyhist/central_nominal.root plots/input/copyhist
fast_plot templates/z_diboson.root plots/input/z_diboson/
if is_stale plots/output/z_diboson/fit.html fitout/z_diboson_lum1.0_templates.root; then
    plotFit.py fitout/z_diboson_lum1.0 plots/output/z_diboson/fit
fi
if is_stale plots/output/z_diboson/fit.html fitout/z_diboson_lum1.0_templates.root; then
    plotFit.py fitout/central_lum1.0 plots/output/central/fit
fi
multi.pl cp plots/output/central/fit_%.pdf $THESIS_PATH/mar6_central_fit_%.pdf
BIN=4j_0b_0t
if is_stale plots/input/qcd_fitted/fitoutput.html ${SHYFT_BASE}/scratch/st-nominal/QCD/fitout/qcdfit_${BIN}_lum1.0_templates.root || [ "$BIN" != "$(cat $BIN)" ]; then
    plotOutputs.py ${SHYFT_BASE}/scratch/st-nominal/QCD/fitout/qcdfit_${BIN}_lum1.0 plots/input/qcd_fitted/
fi
if is_stale plots/input/qcd_fitted/fitoutput.html ${SHYFT_BASE}/scratch/st-nominal/QCD/fitout/qcdfit_${BIN}_lum1.0_templates.root || [ "$BIN" != "$(cat $BIN)" ]; then
    plotOutputs.py ${SHYFT_BASE}/scratch/st-nominal/QCD/fitout/qcdfit_${BIN}_lum1.0 plots/input/qcd_fitted/
fi

echo "$BIN" > plots/input/qcd_fitted/bin.txt
multi.pl cp plots/input/%/_MET_${BIN}.pdf $THESIS_PATH/mar6_%.pdf
cp plots/input/qcd_fitted/fit_${BIN}.pdf $THESIS_PATH/mar6_fitted.pdf
cp plots/input/preqcd/_wMT_1j_0b_0t.pdf  $THESIS_PATH/mar6_preqcd.pdf
cp plots/input/postqcd/_wMT_1j_0b_0t.pdf  $THESIS_PATH/mar6_postqcd.pdf
cp plots/output/z_diboson/fitfit_1j_0b_0t.pdf $THESIS_PATH/mar6_2mu_postfit.pdf
cp plots/output/z_diboson/fitfit_2j_0b_0t.pdf $THESIS_PATH/mar6_3mu_postfit.pdf
cp plots/input/z_diboson/_2muFit_1j_0b_0t.pdf $THESIS_PATH/mar6_2mu_prefit.pdf
cp plots/input/z_diboson/_3muFit_2j_0b_0t.pdf $THESIS_PATH/mar6_3mu_prefit.pdf
cp z_diboson_fit.mrf z_diboson_fit_withbin.mrf
python -c 'import json
f = json.loads(open("fitout/z_diboson_lum1.0_meta.json", "r").read())
print "+ binspergroup = %s" % ",".join([str(x) for x in f["numBinsVec"]])' >> z_diboson_fit_withbin.mrf


configShrinkPlots.py z_diboson_fit_withbin.mrf fitout/z_diboson_lum1.0_templates.root --latex --showCounts | sed 's/1j 0b 0t/2 muon/' | sed 's/2j 0b 0t/3 muon/' | tee $THESIS_PATH/mar6_lepton_fit.tex
echo '\begin{columns}
\begin{column}
\begin{table}
\begin{tabular}{l|r}
Bin & Fitted SF \\
' >  $THESIS_PATH/mar6_sf.tex
grep '[123] Jet ' $THESIS_PATH/fit_central_yield_sf.tex | awk 'BEGIN { FS = "&" } ; { print $1 " & " $4 " \\\\" }' >> $THESIS_PATH/mar6_sf.tex
echo '\end{tabular}
\end{table}
\end{column}
\begin{column}                                                                     
\begin{table}                                                                      
\begin{tabular}{l|r}
Bin & Fitted SF \\' >>  $THESIS_PATH/mar6_sf.tex
grep '[45] Jet ' $THESIS_PATH/fit_central_yield_sf.tex | awk 'BEGIN { FS = "&" } ; { print $1 " & " $4 " \\\\" }' >> $THESIS_PATH/mar6_sf.tex
echo '\end{tabular}
\end{table}
\end{column}
\end{columns}' >> $THESIS_PATH/mar6_sf.tex


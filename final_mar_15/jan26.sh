#!/bin/bash
set -eux
THESIS_PATH="/Users/meloam/Dropbox/thesis/auto_generated/"
if [ 1 -eq 0 ]; then
    fast_plot ${SHYFT_COPYHIST_PATH}/st-nominal/central_nominal.root plots/input/copyhist/
    fast_plot ../scratch/st-nominal/QCD/qcdfit_step2.root plots/input/qcd_step2/
    fast_plot ../scratch/st-nominal/QCD/qcdfit_step3.root plots/input/qcd_step3/
    fast_plot ../scratch/st-nominal/QCD/qcdfit_input.root plots/input/qcd_input/
    fast_plot templates/scaleqcd/central_nominal.root plots/input/qcd_scale/
    fast_plot ${SHYFT_COPYHIST_PATH}/st-nominal/central_qcdMode.root plots/input/qcd_step1/
copyHistograms.py rebin_central.config templates/preqcd.root \
                    file=templates/copyhist/central_nominal.root
copyHistograms.py rebin_central.config templates/postqcd.root \
                    file=templates/scaleqcd/central_nominal.root
fast_plot templates/preqcd.root plots/input/preqcd/
fast_plot templates/postqcd.root plots/input/postqcd/
    fast_plot templates/copyhist/central_nominal.root plots/input/nominal/
fi
fast_plot templates/z_diboson.root plots/input/z_diboson/
plotFit.py fitout/z_diboson_lum1.0 plots/output/z_diboson/fit
plotFit.py fitout/central_lum1.0 plots/output/central/fit
multi.pl cp plots/output/central/fit_%.pdf $THESIS_PATH/jan26_central_fit_%.pdf
BIN=2j_0b_0t
plotOutputs.py ../scratch/st-nominal/QCD/fitout/qcdfit_${BIN}_lum1.0 plots/input/qcd_fitted/
multi.pl cp plots/input/%/_MET_${BIN}.png $THESIS_PATH/jan26_%.png
cp plots/input/qcd_fitted/fit_${BIN}.png $THESIS_PATH/jan26_fitted.png
cp plots/input/preqcd/_wMT_1j_0b_0t.png  $THESIS_PATH/jan26_preqcd.png
cp plots/input/postqcd/_wMT_1j_0b_0t.png  $THESIS_PATH/jan26_postqcd.png
cp plots/output/z_diboson/fitfit_1j_0b_0t.pdf $THESIS_PATH/jan26_2mu_postfit.pdf
cp plots/output/z_diboson/fitfit_2j_0b_0t.pdf $THESIS_PATH/jan26_3mu_postfit.pdf
cp plots/input/z_diboson/_2muFit_1j_0b_0t.png $THESIS_PATH/jan26_2mu_prefit.png
cp plots/input/z_diboson/_3muFit_2j_0b_0t.png $THESIS_PATH/jan26_3mu_prefit.png
cp z_diboson_fit.mrf z_diboson_fit_withbin.mrf
cp plots/output/central
python -c 'import json
f = json.loads(open("fitout/z_diboson_lum1.0_meta.json", "r").read())
print "+ binspergroup = %s" % ",".join([str(x) for x in f["numBinsVec"]])' >> z_diboson_fit_withbin.mrf


configShrinkPlots.py z_diboson_fit_withbin.mrf fitout/z_diboson_lum1.0_templates.root --latex --showCounts | sed 's/1j 0b 0t/2 muon/' | sed 's/2j 0b 0t/3 muon/' | tee $THESIS_PATH/jan26_lepton_fit.tex
echo '\begin{columns}
\begin{column}
\begin{table}
\begin{tabular}{l|r}
Bin & Fitted SF \\
' >  $THESIS_PATH/jan26_sf.tex
grep '[123] Jet ' $THESIS_PATH/fit_central_yield_sf.tex | awk 'BEGIN { FS = "&" } ; { print $1 " & " $4 " \\\\" }' >> $THESIS_PATH/jan26_sf.tex
echo '\end{tabular}
\end{table}
\end{column}
\begin{column}                                                                     
\begin{table}                                                                      
\begin{tabular}{l|r}
Bin & Fitted SF \\' >>  $THESIS_PATH/jan26_sf.tex
grep '[45] Jet ' $THESIS_PATH/fit_central_yield_sf.tex | awk 'BEGIN { FS = "&" } ; { print $1 " & " $4 " \\\\" }' >> $THESIS_PATH/jan26_sf.tex
echo '\end{tabular}
\end{table}
\end{column}
\end{columns}' >> $THESIS_PATH/jan26_sf.tex

sed 's/0.00 \\pm 0.00/\\cellcolor{red} 0.00 \\pm 0.00/' $THESIS_PATH/qcd_event_table.tex > $THESIS_PATH/jan26_qcd_event_table.tex
sed 's/ 0.0 /\\cellcolor{red} 0.0 /' $THESIS_PATH/fit_central_yield_sf.tex | sed 's/382.5/\\cellcolor{red} 382.5/' | sed 's/0.905/\\cellcolor{red} 0.905/'| sed 's/0.870/\\cellcolor{red} 0.870/' > $THESIS_PATH/jan26_fit_central_yield_sf.tex


sed 's/1.84/\\cellcolor{red} 1.84/' $THESIS_PATH/fit_central_factors.tex | sed 's/2.22/\\cellcolor{red} 2.22/' | sed 's/1.53/\\cellcolor{red} 1.53/' | sed 's/0.77/\\cellcolor{red} 0.77/' | sed 's/\(qcdConstr.*\) &/\1 & \\cellcolor{red}/'  > $THESIS_PATH/jan26_fit_central_factors.tex

sed 's/\(qcdConstr.*\) &/\1 \& \\cellcolor{red}/' $THESIS_PATH/fit_central_factors.tex > $THESIS_PATH/jan26_fit_qcd_factors.tex
sed 's/0.77/\\cellcolor{red} 0.77/' $THESIS_PATH/fit_central_factors.tex > $THESIS_PATH/jan26_fit_lftag_factors.tex
sed 's/1.53/\\cellcolor{red} 1.53/' $THESIS_PATH/fit_central_factors.tex | sed 's/2.22/\\cellcolor{red} 2.22/' > $THESIS_PATH/jan26_fit_diboson_factors.tex

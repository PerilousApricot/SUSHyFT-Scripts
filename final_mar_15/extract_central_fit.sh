#!/bin/bash
source ${SHYFT_BASE}/scripts/functions.sh
if [[ "${FAST_MODE:-0}" -ne 0 ]]; then
    exit 0
fi
set -eux
THESIS_PATH="/Users/meloam/Dropbox/thesis/auto_generated/Stop450/"
cp central.mrf central_withbin.mrf
python -c 'import json
f = json.loads(open("fitout/central_lum1.0_meta.json", "r").read())
print "+ binspergroup = %s" % ",".join([str(x) for x in f["numBinsVec"]])' >> central_withbin.mrf
get_uncertainties fitout/log_central.txt
get_scale_factors fitout/log_central.txt


STOP_EVENTS=$(printIntegrals.py -r fitout/central_lum1.0_templates.root:Stop450_update | xargs printf '%0.2f')
STOP_EVENTS_UNC=$(perl -e "print $STOP_EVENTS / $Stop450_SF * $Stop450_UNC" | xargs printf '%0.2f')

TOP_EVENTS=$(printIntegrals.py -r fitout/central_lum1.0_templates.root:^Top_update | xargs printf '%0.2f')
TOP_EVENTS_UNC=$(perl -e "print $TOP_EVENTS / $Top_SF * $Top_UNC" | xargs printf '%0.2f')

WJETS_EVENTS=$(printIntegrals.py -r fitout/central_lum1.0_templates.root:WJets_update | xargs printf '%0.2f')
WJETS_EVENTS_UNC=$(perl -e "print $WJETS_EVENTS / $WJets_SF * $WJets_UNC" | xargs printf '%0.2f')

ZJETS_EVENTS=$(printIntegrals.py -r fitout/central_lum1.0_templates.root:ZJets_update | xargs printf '%0.2f')
ZJETS_EVENTS_UNC=$(perl -e "print $ZJETS_EVENTS / $ZJets_SF * $ZJets_UNC" | xargs printf '%0.2f')

DIBOSON_EVENTS=$(printIntegrals.py -r fitout/central_lum1.0_templates.root:DiBoson_update | xargs printf '%0.2f')
DIBOSON_EVENTS_UNC=$(perl -e "print $DIBOSON_EVENTS / $DiBoson_SF * $DiBoson_UNC" | xargs printf '%0.2f')

SINGLETOP_EVENTS=$(printIntegrals.py -r fitout/central_lum1.0_templates.root:SingleTop_update | xargs printf '%0.2f')
SINGLETOP_EVENTS_UNC=$(perl -e "print $SINGLETOP_EVENTS / $SingleTop_SF * $SingleTop_UNC" | xargs printf '%0.2f')

QCD_EVENTS=$(printIntegrals.py -r fitout/central_lum1.0_templates.root:QCD_update | xargs printf '%0.2f')
QCD_EVENTS_UNC=$(perl -e "print $QCD_EVENTS / $QCD_SF * $QCD_UNC" | xargs printf '%0.2f')

BACKGROUND_TOTAL=$( perl -e "printf '%0.2f', $TOP_EVENTS + $WJETS_EVENTS + $ZJETS_EVENTS + $DIBOSON_EVENTS + $SINGLETOP_EVENTS + $QCD_EVENTS" )
BACKGROUND_TOTAL_UNC=$( perl -e "printf '%0.2f', sqrt($TOP_EVENTS_UNC ** 2 + $WJETS_EVENTS_UNC ** 2 + $ZJETS_EVENTS_UNC ** 2 + $DIBOSON_EVENTS_UNC ** 2 + $SINGLETOP_EVENTS_UNC ** 2)" )
DATA_EVENTS=$(printIntegrals.py -rv 'fitout/central_lum1.0_templates.root:newdata' | head -n 1  | awk '{ print $2 }' | xargs printf '%0.0f')

# Since the mass gets sedded
MY_MASS="$(echo Stop450 | sed 's/Stop//')"

echo "$MY_MASS & \$ ${DATA_EVENTS} \$ & \$ ${STOP_EVENTS} \\pm $STOP_EVENTS_UNC \$ & \$ $BACKGROUND_TOTAL \\pm $BACKGROUND_TOTAL_UNC \$ \\\\" | tee $THESIS_PATH/fit_short_results_row.tex

configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root --latex --showCounts | tee $THESIS_PATH/fit_central_yield.tex
while read -r LINE; do
    if [[ "$LINE" == *"Total Pred"* ]]; then
        echo "$LINE" | sed 's/Total Pred/Total Pred \& SF/'
    elif [[ "$LINE" == *Jet* || "$LINE" == Total* ]]; then
        IFS='&' read -ra ADDR <<< "$LINE"
        echo -n "${ADDR[0]} & ${ADDR[1]} & ${ADDR[2]} &"
        perl -e "print ${ADDR[1]} / ${ADDR[2]}" | xargs printf '%.3f'
        COUNT=$((${#ADDR[@]} - 1))
        for i in `seq 3 $COUNT`; do
            echo -n "& ${ADDR[$i]}"
        done
        echo ''
    elif [[ "$LINE" == *begin{tabular* ]]; then
        echo "$LINE" | sed 's/| r |/| r | r |/'
    else
        echo "$LINE"
    fi
done < $THESIS_PATH/fit_central_yield.tex | tee $THESIS_PATH/fit_central_yield_sf.tex
#rm -f fitout/pretty_log*.pdf fitout/jetline_pretty*.pdf
if [ "${NO_PLOT:-0}" -eq 0 ]; then
# 0 taus
JETLINE_UNIT="m_{T}(l,MET) (GeV) or sumEt (GeV)"
WMT_AXIS1="1:50_90:300"
WMT_AXIS2="5:50_90:300"
SET_AXIS1="1:100_80:1000"
SET_AXIS2="5:100_80:1000"
#    --axisLabel _1j_~${WMT_AXIS1},_2j_~${WMT_AXIS2},_3j_~${WMT_AXIS2} \
#    --axisLabel _4j_~${SET_AXIS1},_5j_~${SET_AXIS2} \

configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/jetline_pretty.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_wMT_1j_0b_0t,_wMT_2j_0b_0t,_wMT_3j_0b_0t,_sumEt_4j_0b_0t,_sumEt_5j_0b_0t \
    --axisLabel _1j_~${WMT_AXIS1},_2j_~${WMT_AXIS2},_3j_~${WMT_AXIS2} \
    --axisLabel _4j_~${SET_AXIS1},_5j_~${SET_AXIS2} \
    --units="$JETLINE_UNIT" \
    --yaxis "Events/Bin"
configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/jetline_pretty.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_wMT_1j_1b_0t,_wMT_2j_1b_0t,_wMT_3j_1b_0t,_sumEt_4j_1b_0t,_sumEt_5j_1b_0t \
    --axisLabel _1j_~${WMT_AXIS1},_2j_~${WMT_AXIS2},_3j_~${WMT_AXIS2} \
    --axisLabel _4j_~${SET_AXIS1},_5j_~${SET_AXIS2} \
    --units="$JETLINE_UNIT" \
    --yaxis "Events/Bin"
configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/jetline_pretty.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_wMT_2j_2b_0t,_wMT_3j_2b_0t,_sumEt_4j_2b_0t,_sumEt_5j_2b_0t \
    --axisLabel _2j_~${WMT_AXIS1},_3j_~${WMT_AXIS2} \
    --axisLabel _4j_~${SET_AXIS1},_5j_~${SET_AXIS2} \
    --units="$JETLINE_UNIT" \
    --yaxis "Events/Bin"

# 1 taus
configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/jetline_pretty.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_wMT_1j_0b_1t,_wMT_2j_0b_1t,_wMT_3j_0b_1t,_sumEt_4j_0b_1t,_sumEt_5j_0b_1t \
    --units="$JETLINE_UNIT" \
    --axisLabel _1j_~${WMT_AXIS1},_2j_~${WMT_AXIS2},_3j_~${WMT_AXIS2} \
    --axisLabel _4j_~${SET_AXIS1},_5j_~${SET_AXIS2} \
    --yaxis "Events/Bin"
configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/jetline_pretty.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_wMT_2j_1b_1t,_wMT_3j_1b_1t,_sumEt_4j_1b_1t,_sumEt_5j_1b_1t \
    --units="$JETLINE_UNIT" \
    --axisLabel _2j_~${WMT_AXIS1},_3j_~${WMT_AXIS2} \
    --axisLabel _4j_~${SET_AXIS1},_5j_~${SET_AXIS2} \
    --yaxis "Events/Bin"
configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/jetline_pretty.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_wMT_3j_2b_1t,_sumEt_4j_2b_1t,_sumEt_5j_2b_1t \
    --axisLabel _3j_~${WMT_AXIS1} \
    --axisLabel _4j_~${SET_AXIS1},_5j_~${SET_AXIS2} \
    --units="$JETLINE_UNIT" \
    --yaxis "Events/Bin"
cp fitout/jetline_pretty* $THESIS_PATH/

configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/pretty_log.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_wMT_1j_0b_0t,_wMT_1j_1b_0t,_wMT_1j_0b_1t \
    --axisLabel 1:0_29:150 --units="m_{T}(l,MET) (GeV)" \
    --yaxis "Events" --logY
configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/pretty_log.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_wMT_2j_0b_0t,_wMT_2j_1b_0t,_wMT_2j_0b_1t,_wMT_2j_2b_0t \
    --axisLabel 1:0_29:150 --units="m_{T}(l,MET) (GeV)" \
    --yaxis "Events" --logY
configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/pretty_log.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_wMT_3j_0b_0t,_wMT_3j_1b_0t,_wMT_3j_0b_1t,_wMT_3j_2b_0t,_wMT_3j_2b_1t \
    --axisLabel 1:0_29:150 --units="m_{T}(l,MET) (GeV)" \
    --yaxis "Events" --logY
configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/pretty_log.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_sumEt_4j_0b_0t,_sumEt_4j_1b_0t,_sumEt_4j_0b_1t,_sumEt_4j_2b_0t,_sumEt_4j_2b_1t \
    --axisLabel 1:0_99:1000 --units="sumEt (GeV)" \
    --yaxis "Events"
configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/pretty_log.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_sumEt_5j_0b_0t,_sumEt_5j_1b_0t,_sumEt_5j_0b_1t,_sumEt_5j_2b_0t,_sumEt_5j_2b_1t \
    --axisLabel 1:0_99:1000 --units="\\sum{E_{T}} (GeV)" \
    --yaxis "Events"

cp fitout/pretty_*.pdf $THESIS_PATH/

configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/jetrow.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_wMT_1j_0b_0t,_wMT_1j_1b_0t,_wMT_1j_0b_1t \
    --axisLabel 1:0_29:150 --units="m_T(l,MET) (GeV)" \
    --yaxis "Events"
configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/jetrow.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_wMT_2j_0b_0t,_wMT_2j_1b_0t,_wMT_2j_0b_1t,_wMT_2j_2b_0t \
    --axisLabel 1:0_29:150 --units="m_T(l,MET) (GeV)" \
    --yaxis "Events"
configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/jetrow.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_wMT_3j_0b_0t,_wMT_3j_1b_0t,_wMT_3j_0b_1t,_wMT_3j_2b_0t,_wMT_3j_2b_1t \
    --axisLabel 1:0_29:150 --units="m_T(l,MET) (GeV)" \
    --yaxis "Events"
configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/jetrow.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_sumEt_4j_0b_0t,_sumEt_4j_1b_0t,_sumEt_4j_0b_1t,_sumEt_4j_2b_0t,_sumEt_4j_2b_1t \
    --axisLabel 1:0_99:1000 --units="sumEt (GeV)" \
    --yaxis "Events"
configShrinkPlots.py central_withbin.mrf fitout/central_lum1.0_templates.root fitout/jetrow.pdf \
    --text "    CMS UNOFFICIAL   #sqrt{s} = 8 TeV       19.635 fb^{-1}"  \
    --groups=_sumEt_5j_0b_0t,_sumEt_5j_1b_0t,_sumEt_5j_0b_1t,_sumEt_5j_2b_0t,_sumEt_5j_2b_1t \
    --axisLabel 1:0_99:1000 --units="sumEt (GeV)" \
    --yaxis "Events"

cp fitout/jetrow_*.pdf $THESIS_PATH/

(
cd fitout
echo "\\begin{figure}[htbp]
\\centering"
for FILE in pretty_log_wMT*.pdf; do
echo "\\resizebox{0.40\\linewidth}{!}{\\includegraphics{auto_generated/${FILE}}}"
done
echo "
\\caption{\\label{fig:result_123bin}Output distributions for 1/2/3 jet bins}
\\end{figure}
\\begin{figure}[htbp]
\\centering"
for FILE in pretty_log_sumEt*.pdf; do
echo "\\resizebox{0.40\\linewidth}{!}{\\includegraphics{auto_generated/Stop450/${FILE}}}"
done
echo "\\caption[Output distributions for 4/5 jet bins]{\\label{fig:result_45bin}Output distributions for 4/5 jet bins (log scale)}
\\end{figure}"
) | tee $THESIS_PATH/pretty_log_includes.tex

(
cd fitout
echo '\begin{figure}[htbp]
\centering
\adjustbox{max height=\dimexpr\textheight-5.5cm\relax,
           max width=\textwidth}{
\begin{tabular}{ccc}
\multicolumn{3}{c}{\includegraphics{legend}} \\ '
COUNT=0
for FILE in jetline_pretty*_0t_*.pdf; do
echo "\\includegraphics{auto_generated/Stop450/${FILE}}"
if [ $COUNT -eq 2 ]; then
    echo ' \\ '
else
    echo ' & '
fi
COUNT=$((COUNT+1))
done
COUNT=0
for FILE in jetline_pretty*_1t_*.pdf; do
echo "\\includegraphics{auto_generated/Stop450/${FILE}}"
if [ $COUNT -eq 2 ]; then
    echo ' \\ '
else
    echo ' & '
fi
COUNT=$((COUNT+1))
done
echo '\end{tabular}}
\caption{Output kinematic distributions. The fitted $N_{jet} \le 3$/$N_{jet} \gt 3$ distributions
are $m_{T}(\mu,MET)$/$\sum{E_{T}}$, respectively.}
\end{figure}'
echo "%got jetline"
) | tee $THESIS_PATH/jetline_pretty_includes.tex
(
### jetrow
cd fitout
echo '\begin{figure}[htbp]
\centering
\adjustbox{max height=\dimexpr\textheight-5.5cm\relax,
           max width=\textwidth}{
\begin{tabular}{ccc}
\multicolumn{3}{c}{\includegraphics{legend}} \\ '
COUNT=0
for FILE in jetrow_{wMT,sumEt}_*.pdf; do
    echo "\\includegraphics{auto_generated/Stop450/${FILE}}"
    if [ $COUNT -eq 2 ]; then
        echo ' \\ '
    else
        echo ' & '
    fi
    COUNT=$((COUNT+1))
done
echo '\end{tabular}}
\caption{Output kinematic distributions. The fitted $N_{jet} \le 3$/$N_{jet} \gt 3$ distributions
are $m_{T}(\mu,MET)$/$\sum{E_{T}}$, respectively.}
\end{figure}'
echo "%got jetline"
) | tee $THESIS_PATH/jetrow_pretty_includes.tex

(cd fitout
for BIN in 0b_0t 0b_1t 1b_0t 1b_1t 2b_0t 2b_1t; do
echo "\\includegraphics{auto_generated/Stop450/$(echo jetline_pretty_wMT_?j_${BIN}*.pdf)}" > $THESIS_PATH/onerightline_${BIN}.tex
done
for BIN in 1j 2j 3j 4j 5j; do
echo "\\includegraphics{auto_generated/Stop450/$(echo jetrow_*_${BIN}_0b_0t*.pdf)}" > $THESIS_PATH/onejetrow_${BIN}.tex
done

)
fi

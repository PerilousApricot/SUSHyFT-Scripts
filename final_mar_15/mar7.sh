#!/bin/bash
source ${SHYFT_BASE}/scripts/functions.sh
source functions.sh
set -eux
THESIS_PATH="/Users/meloam/Dropbox/thesis/auto_generated/Stop450/"

for BINTYPE in onebin jetbin tagbin jettagbin jettaubin jettagtaubin; do
    if is_stale mar7_${BINTYPE}.root mar7_combine_${BINTYPE}.config templates/nominal/nominal.root; then
        copyHistograms.py mar7_combine_${BINTYPE}.config mar7_${BINTYPE}.root file=templates/nominal/nominal.root
        fast_plot mar7_${BINTYPE}.root plots/input/mar7_${BINTYPE}/
    fi
done
cp plots/input/mar7_onebin/_wMT_1j_0b_0t.pdf $THESIS_PATH/mar7_onebin.pdf
multi.pl cp plots/input/mar7_jetbin/_wMT_%_0b_0t.pdf $THESIS_PATH/mar7_jetbin_%.pdf
multi.pl cp plots/input/mar7_tagbin/_wMT_%j_%%_0t.pdf $THESIS_PATH/mar7_tagbin_%%.pdf
multi.pl cp plots/input/mar7_jettagbin/_wMT_%_%%_0t.pdf $THESIS_PATH/mar7_jettagbin_%_%%.pdf
multi.pl cp plots/input/mar7_jettaubin/_wMT_%t.pdf $THESIS_PATH/mar7_jettaubin_%t.pdf
multi.pl cp plots/input/mar7_jettagtaubin/_wMT_%t.pdf $THESIS_PATH/mar7_jettagtaubin_%t.pdf

configShrinkPlots.py z_diboson_fit_withbin.mrf fitout/z_diboson_lum1.0_templates.root --latex --showCounts | sed 's/1j 0b 0t/2 muon/' | sed 's/2j 0b 0t/3 muon/' | tee $THESIS_PATH/mar7_lepton_fit.tex


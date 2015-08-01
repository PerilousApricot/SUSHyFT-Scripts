#!/bin/bash
plotOutputs.py
OUT=/Users/meloam/Dropbox/thesis/auto_generated
cp $SHYFT_BASE/web/st-nominal/fit_*.pdf $OUT
fitToTex.py --fit $SHYFT_BASE/output/st-nominal/central_nominal.txt > $OUT/results_factors.tex
fitToTex.py --correlation $SHYFT_BASE/output/st-nominal/central_nominal.txt > $OUT/results_correlation.tex

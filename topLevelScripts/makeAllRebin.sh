#!/bin/bash
OUTDIR=/scratch/meloam/auto_rebin
(for FILE in /scratch/meloam/auto_hadd/*.root; do echo $FILE; done) | \
    parallel --eta -j 8 ./runIfChanged.sh $OUTDIR/ttbar_notau_{/} {} -- ./rebinHists.py --tagMode=ttbar_notau --outDir=$OUTDIR {}

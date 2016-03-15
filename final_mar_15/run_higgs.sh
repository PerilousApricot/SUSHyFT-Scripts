#!/bin/bash
unset TERM
set -xue
date
for DIR in 250 300 350 400 450 500 600; do
    cd Stop$DIR
    rm -f log.txt
    rm -f status.txt
    ( ( set -x ; combine higgs_datacard.txt -M Asymptotic --saveWorkspace -V -s -1 -v 2 2>&1 ; echo -n "$?" > status.txt) | tee log.txt ; echo "Logged to $(pwd)/log.txt" ) &
    cd -
done
echo "Waiting..."
jobs
wait
echo "Done Waiting..."
jobs
for DIR in 250 300 350 400 450 500 600; do
    echo "****Stop${DIR}"
    if [[ "$(cat Stop${DIR}/status.txt)" != "0" ]]; then
        echo "FAILED"
        rm Stop${DIR}/*
    else
        cat Stop${DIR}/log.txt
    fi
done

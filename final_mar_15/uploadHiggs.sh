#!/bin/bash
mkdir -p higgs_upload/Stop{250,300,350,400,450,500,600}
cp run_higgs.sh higgs_upload/run.sh
for DIR in 250 300 350 400 450 500 600; do
    rm higgs_upload/Stop$DIR/*
    cp masses/Stop$DIR/higgs_datacard.txt higgs_upload/Stop$DIR
    cp masses/Stop$DIR/higgs/nominal_all.root higgs_upload/Stop$DIR
    cp masses/Stop$DIR/stop_sf.txt higgs_upload/Stop$DIR/stop_sf.txt
done

mkdir -p higgs_upload/OLD/Stop{250,300,350,400,450,500,600}

for DIR in 250 300 350 400 450 500 600; do
    rm higgs_upload/OLD/Stop$DIR/*
    cp masses/OLD/Stop$DIR/higgs_datacard.txt higgs_upload/OLD/Stop$DIR
    cp masses/OLD/Stop$DIR/higgs/nominal_all.root higgs_upload/OLD/Stop$DIR
    cp masses/OLD/Stop$DIR/stop_sf.txt higgs_upload/OLD/Stop$DIR/stop_sf.txt
done

mkdir -p higgs_upload/noscale/Stop{250,300,350,400,450,500,600}

for DIR in 250 300 350 400 450 500 600; do
    rm higgs_upload/noscale/Stop$DIR/*
    cp masses/Stop$DIR/higgsnoscale_datacard.txt higgs_upload/noscale/Stop$DIR/higgs_datacard.txt
    cp masses/Stop$DIR/higgsnoscale/nominal_all.root higgs_upload/noscale/Stop$DIR
    echo "1.0" > higgs_upload/noscale/Stop$DIR/stop_sf.txt
done

rsync --delete -avh higgs_upload login.accre.vanderbilt.edu:/scratch/meloam/SUSHyFT-Scripts

ssh login.accre.vanderbilt.edu ./run-combine.sh

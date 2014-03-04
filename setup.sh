#!/bin/bash

# ››› SUSHyFT - Andrew Melo, on the shoulders of others

# Where are we? (Get right bash magic to autodetect)
export SUSHYFT_BASE=$(dirname $(readlink -f "$BASH_SOURCE"))

# Which analysis are we doing? Determines input datasets, binning procedure
export SUSHYFT_MODE="ttbar_notau"

# Where are we storing our output datasets?
SUSHYFT_DATA_BASE=$SUSHYFT_BASE/data
export SUSHYFT_EDNTUPLE_PATH=$SUSHYFT_DATA_BASE/auto_edntuple
export SUSHYFT_FWLITE_PATH=$SUSHYFT_DATA_BASE/auto_fwlite
export SUSHYFT_HADD_PATH=$SUSHYFT_DATA_BASE/auto_hadd
export SUSHYFT_REBIN_PATH=$SUSHYFT_DATA_BASE/auto_rebin

# What are the input datasets (starting from PAT)
export SUSHYFT_DATASET_INPUT=$SUSHYFT_BASE/config/$SUSHYFT_MODE/input_pat.txt

# Where are we storing the state of processing?
export SUSHYFT_STATE_PATH=$SUSHYFT_BASE/state

# What are the versions of processing we'd like?
export SUSHYFT_EDNTUPLE_VERSION="v2"
export SUSHYFT_EDNTUPLE_CMSSW_BASE="FIXME123"

# Where to put CRAB scratch stuff
export SUSHYFT_SCRATCH_PATH=$SUSHYFT_BASE/scratch


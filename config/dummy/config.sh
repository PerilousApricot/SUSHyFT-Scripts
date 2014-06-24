# Per-configuration variables

SUSHYFT_SEPARATE_QCD_FIT=1
SUSHYFT_ENABLE_SYSTEMATICS=1

# What are the versions of processing we'd like?
export SUSHYFT_EDNTUPLE_VERSION="v2"
export SUSHYFT_EDNTUPLE_CMSSW_BASE="FIXME123"

# jet tag tau
SUSHYFT_QCD_JETTAG=( 
                    "1 0 0 wMT"
                    "2 0 0 wMT"
                    "3 0 0 wMT"
                    "4 0 0 wMT"
                    "5 0 0 wMT"
                    "1 1 0 svm"
                    "2 1 0 svm"
                    "3 1 0 svm"
                    "4 1 0 svm"
                    "5 1 0 svm"
                    "2 2 0 svm"
                    "3 2 0 svm"
                    "4 2 0 svm"
                    "5 2 0 svm"
                    )


SUSHYFT_SYSTEMATIC_LIST=( "qcd.mrf" "btag_sf.mrf" )

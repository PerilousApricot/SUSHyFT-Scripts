# Per-configuration variables

SUSHYFT_SEPARATE_QCD_FIT=0
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
SUSHYFT_SYST_BTAG_COMBINE="2jet:_svm_2j_1b_1t+_svm_2j_2b_1t,3jet:_svm_3j_1b_1t+_svm_3j_2b_1t,4jet:_svm_4j_1b_1t+_svm_4j_2b_1t,5t:_svm_5j_1b_1t+_svm_5j_2b_1t,1jet:_svm_1j_1b_1t"
SUSHYFT_SYSTEMATIC_LIST=( "btag_sf.mrf" )

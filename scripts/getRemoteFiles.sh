#!/bin/bash
rsync -avh --progress --exclude ".shyft-*" --exclude ".sushyft-*" --delete -c "${SHYFT_REMOTE_PATH}/data/auto_rebin/*/*.root" ${SHYFT_REBIN_PATH}
rsync -avh "${SHYFT_REMOTE_PATH}/state/lumisum*" ${SHYFT_STATE_PATH}

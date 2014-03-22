#!/bin/bash

rsync -avh --dry-run --exclude ".sushyft-*" ${SUSHYFT_REMOTE_PATH}/data/auto_hadd ${SUSHYFT_HADD_PATH}
rsync -avh ${SUSHYFT_REMOTE_PATH}/state/lumisum* ${SUSHYFT_STATE_PATH}

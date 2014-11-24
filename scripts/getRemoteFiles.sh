#!/bin/bash
rsync -avh --progress --exclude ".shyft-*" --delete -c ${SHYFT_REMOTE_PATH}/data/auto_hadd/ ${SHYFT_HADD_PATH}
rsync -avh ${SHYFT_REMOTE_PATH}/state/lumisum* ${SHYFT_STATE_PATH}

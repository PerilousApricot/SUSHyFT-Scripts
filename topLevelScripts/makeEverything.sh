#!/bin/bash
(
    source ${SHYFT_BASE}/config/enabledConfigs.sh

    for CONFIG in ${SHYFT_ENABLED_CONFIGS}; do
        (SHYFT_MODE=${CONFIG} makeThesis.sh) &
    done
    wait
    if [[ -e "/Users/meloam/Dropbox/web" ]]; then
        rsync -r -c ${SHYFT_BASE}/web/ /Users/meloam/Dropbox/web
    fi
)

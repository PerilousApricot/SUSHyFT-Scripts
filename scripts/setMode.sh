#!/bin/bash

SCRIPTPATH="${BASH_SOURCE[0]}"

function sushyft_mode_usage() {
    >&2 echo " Usage: source ${BASH_SOURCE} TASK
    -or-
 Usage: ${BASH_SOURCE} TASK (limited functionality)
    -or-
 Usage: sushyft mode TASK (preferred, see note)

 Tasks:
  sushyft mode list          # Lists valid configurations
  sushyft mode set <mode>    # Changes the current SUSHyFT configuration.
  sushyft mode help          # Shows usage for this task

 Note:
  The preferred way to access the command requires using the One True Shell
  (bash) and sourcing the following script to gain the helper environment

    ${SUSHYFT_TEMP_BASE:-\$SUSHYFT_BASE}/scripts/sushyft_source.sh"
}

SUSHYFT_TEMP_BASE=$(cd "$(dirname $(dirname "${SCRIPTPATH}"))" ; pwd)
case $1 in
    _loadusage)
        # noop
        unset SUSHYFT_TEMP_BASE
        return 0
        ;;
    ""|list)
        for DIR in $(ls -d $SUSHYFT_TEMP_BASE/config/*); do
            if [ ! -d $DIR ]; then
                continue
            fi
            echo $(basename $DIR)
        done ;;
    set)
        if [ "$0" = "$BASH_SOURCE" ]; then
            >&2 echo "ERROR: This script must be sourced to work automatically"
        fi
        SUSHYFT_TEMP_PATH="${SUSHYFT_BASE}/config/$2"
        if [ -z "$2" ]; then
            sushyft_mode_usage
            unset SUSHYFT_TEMP_BASE
            unset SUSHYFT_TEMP_PATH
            return 1
        fi
        if [ ! -d ${SUSHYFT_TEMP_PATH} ]; then
            >&2 echo "ERROR: Unknown configuration"
            unset SUSHYFT_TEMP_BASE
            unset SUSHYFT_TEMP_PATH
            return 1
        fi
        if [ "$0" = "$BASH_SOURCE" ]; then
            echo "export SUSHYFT_MODE=$2"
        else
            export SUSHYFT_MODE="$2"
        fi
        ;;

    *|help)
        sushyft_mode_usage ;;
esac


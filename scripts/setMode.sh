#!/bin/bash

SCRIPTPATH="${BASH_SOURCE[0]}"

function shyft_mode_usage() {
    >&2 echo " Usage: source ${BASH_SOURCE} TASK
    -or-
 Usage: ${BASH_SOURCE} TASK (limited functionality)
    -or-
 Usage: shyft mode TASK (preferred, see note)

 Tasks:
  shyft mode list          # Lists valid configurations
  shyft mode set <mode>    # Changes the current SHyFT configuration.
  shyft mode help          # Shows usage for this task

 Note:
  The preferred way to access the command requires using the One True Shell
  (bash) and sourcing the following script to gain the helper environment

    ${SHYFT_TEMP_BASE:-\$SHYFT_BASE}/scripts/shyft_source.sh"
}

SHYFT_TEMP_BASE=$(cd "$(dirname $(dirname "${SCRIPTPATH}"))" ; pwd)
case $1 in
    _loadusage)
        # noop
        unset SHYFT_TEMP_BASE
        return 0
        ;;
    ""|list)
        for DIR in $(ls -d $SHYFT_TEMP_BASE/config/*); do
            if [ ! -d $DIR ]; then
                continue
            fi
            echo $(basename $DIR)
        done ;;
    set)
        if [ "$0" = "$BASH_SOURCE" ]; then
            >&2 echo "ERROR: This script must be sourced to work automatically"
        fi
        SHYFT_TEMP_PATH="${SHYFT_BASE}/config/$2"
        if [ -z "$2" ]; then
            shyft_mode_usage
            unset SHYFT_TEMP_BASE
            unset SHYFT_TEMP_PATH
            return 1
        fi
        if [ ! -d ${SHYFT_TEMP_PATH} ]; then
            >&2 echo "ERROR: Unknown configuration"
            unset SHYFT_TEMP_BASE
            unset SHYFT_TEMP_PATH
            return 1
        fi
        if [ "$0" = "$BASH_SOURCE" ]; then
            echo "export SHYFT_MODE=$2"
        else
            export SHYFT_MODE="$2"
        fi
        ;;

    *|help)
        shyft_mode_usage ;;
esac


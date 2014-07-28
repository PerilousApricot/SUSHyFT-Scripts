# this function should be source in the context of your shell like so:
# source $SUSHYFT_BASE/scripts/sushyft_source.sh
# Once the sushyft() function is defined, you can type "sushyft" to access
# some handy helper functions

SCRIPTPATH="${BASH_SOURCE[0]}"
SUSHYFT_BASE="$(cd "$(dirname $(dirname "${SCRIPTPATH}"))" ; pwd)"

function sushyft() {
    # only some subcommands need to be sourced
    if [ "$1" = "mode" ]; then
        shift
        source ${SUSHYFT_BASE}/scripts/setMode.sh "$@"
        # the rest should be executed externally (keep the namespace tidy)
    else
        ${SUSHYFT_BASE}/scripts/entryHelper.sh "$@"
    fi
}

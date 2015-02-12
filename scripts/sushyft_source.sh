# this function should be source in the context of your shell like so:
# source $SHYFT_BASE/scripts/shyft_source.sh
# Once the shyft() function is defined, you can type "shyft" to access
# some handy helper functions

SCRIPTPATH="${BASH_SOURCE[0]}"
SHYFT_BASE="$(cd "$(dirname $(dirname "${SCRIPTPATH}"))" ; pwd)"

function shyft() {
    # only some subcommands need to be sourced
    if [ "$1" = "mode" ]; then
        shift
        source ${SHYFT_BASE}/scripts/setMode.sh "$@"
        # the rest should be executed externally (keep the namespace tidy)
    else
        ${SHYFT_BASE}/scripts/entryHelper.sh "$@"
    fi
}

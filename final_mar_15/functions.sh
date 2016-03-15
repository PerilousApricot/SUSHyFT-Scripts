function is_stale () {
    local DEST; DEST=$1 ; shift
    local SOURCE
    [ ! -e "$DEST" ] && echo "Stale: Dest $DEST doesn't exist" && return 0
    for SOURCE in "$@"; do
        if [ ! -e "$SOURCE" ]; then
            echo "Stale: Source $SOURCE doesn't exist"
            return 0
        fi
        if [ "$SOURCE" -nt "$DEST" ]; then
            echo "Stale: $SOURCE -nt $DEST"
            #echo "StaleAll: $DEST -- $@"
            #stat $SOURCE
            #stat $DEST
            return 0
        fi
    done
    echo "Not stale: $SOURCE -- $@"
    return 1
}

function fast_plot() {
    set -eux
    if is_stale "$2/index.html" "$1"; then
        plotHistogram.py "$1" "$2"
    fi
}


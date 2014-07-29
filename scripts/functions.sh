function getDatasetEventsFromDAS {
    # finds and returns nEvents from das, regardless of instance
    # the dataset is stored in
    # $1 - dataset name
    if [[ $1 =~ 'StoreResults' ]]; then
        local INSTANCELIST=("" "instance=analysis02" "instance=analysis03" "instance=analysis01")
    else
        local INSTANCELIST=("instance=analysis02" "instance=analysis03" "instance=analysis01" "")
    fi
    for INSTANCE in $INSTANCELIST; do
        local VAL=$(das.py --query "dataset dataset=$1 $INSTANCE | grep dataset.nevents" | grep -o [0-9]*)
        # need to get something to test if this is actually numeric
        if [[ ! -z $VAL && $VAL -gt 0 ]]; then
            echo $VAL
            return
        fi
    done
    echo 0
}

function getDatasetShortname () {
    # takes a dataset name and returns something compact with slashes
    # removed
    if [[ $1 =~ "MET" || $1 =~ "SingleMu" ]]; then
        echo $1 | tr '/' ' ' | tr '_' ' ' | awk '{ print $1 $5 $6 }'
    else
        echo $1 | tr '/' ' ' | awk '{ print $1 "_" $2 }'
    fi
}

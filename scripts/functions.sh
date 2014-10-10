function getDatasetEventsFromDAS {
    # finds and returns nEvents from das, regardless of instance
    # the dataset is stored in
    # $1 - dataset name
    if [[ -z "$2" ]]; then 
        if [[ $1 =~ 'StoreResults' ]]; then
            local INSTANCELIST=("global" "phys02" "phys03" "phys01")
        else
            local INSTANCELIST=("phys02" "phys03" "phys01" "global")
        fi
    else
        local INSTANCELIST=( $2 )
    fi
    for INSTANCE in ${INSTANCELIST[@]}; do
        local VAL=$(set -o pipefail ; das.py --query="dataset dataset=$1 instance=prod/$INSTANCE | grep dataset.nevents" | grep -o [0-9]*)
        if [ $? -ne 0 ]; then
            continue
        fi
        # need to get something to test if this is actually numeric
        if [[ ! -z "$VAL" && $VAL -gt 0 ]]; then
            echo "$VAL $INSTANCE"
            return
        fi
    done
    echo "0 0"
}

function getDatasetShortname () {
    # takes a dataset name and returns something compact with slashes
    # removed
    echo $1 | tr '/' ' ' | awk '{ print $1 "_" $2 }'
}

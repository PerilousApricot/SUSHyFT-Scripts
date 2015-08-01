#!/bin/bash

# drops in jobs for a single dataset

if [[ $# -lt 4 ]]; then
    echo "Usage: $0 file_list working_dir is_data sample_name [args for fwlite]"
    exit 1
fi

USERSLIST=$1;shift
WORKDIR=$1;shift
if [[ $1 -eq 1 ]]; then
    OURDATA="--useData"
else
    OURDATA=""
fi
shift
SAMPLE=$1;shift
# do PBS for now, condor should be simple as well

if [ ! -d $WORKDIR ]; then
    mkdir -e $WORKDIR
fi

if [ -f $WORKDIR/makelock ]; then
    echo "Lockfile already exists $WORKDIR/makelock"
    exit 1
fi

touch $WORKDIR/makelock
if [[ "x$@" =~ nominal ]]; then
    PRIORITY="+150"
else
    PRIORITY="+100"
fi
RETRYCOUNT=0
COUNT=0
SPLITCOUNT=0
while [[ -e $WORKDIR/input_${RETRYCOUNT}_0.txt ]]; do
    RETRYCOUNT=$((RETRYCOUNT + 1))
done
while true; do
    split_file.sh $USERSLIST 50 $SPLITCOUNT > $WORKDIR/input_${RETRYCOUNT}_$COUNT.txt
    if [[ ! -s $WORKDIR/input_${RETRYCOUNT}_$COUNT.txt ]]; then
        COUNT=$(( $COUNT - 1 ))
        break
    fi
    touch $WORKDIR/marker_$RETRYCOUNT_$COUNT.txt
    COUNT=$(( $COUNT + 1 ))
    SPLITCOUNT=$(( SPLITCOUNT + 1 ))
done

sbatch -a 0-${COUNT} << EOF
#!/bin/bash
#SBATCH --mem 1900mb
#SBATCH -t 12:00:00
#SBATCH -o $WORKDIR/stdout_${RETRYCOUNT}_%a.txt
#SBATCH -A jswhep
if [[ ! -e $WORKDIR ]]; then
    mkdir -p $WORKDIR
fi
cd ~
. set-analysis.sh
COUNT=\$SLURM_ARRAY_TASK_ID
echo "input list is $WORKDIR/input_${RETRYCOUNT}_\$COUNT.txt"
hostname
set -fx
if [[ -e $WORKDIR/output_${RETRYCOUNT}_\$COUNT.root ]]; then
    echo "FAILED OVERWRITE" >> $WORKDIR/FAILED.${RETRYCOUNT}_\$COUNT
    cat $WORKDIR/input_${RETRYCOUNT}_\$COUNT.txt >> $WORKDIR/FAILED.${RETRYCOUNT}_\$COUNT
    exit 1
fi
rm $WORKDIR/${RETRYCOUNT}_\$COUNT.root
echo "Started at \$(date)" >> $WORKDIR/FAILED.${RETRYCOUNT}_\$COUNT
echo "At dir: \$(pwd)"
ls -lah
time python2.6 refactor_fwlite.py --inputListFile=$WORKDIR/input_${RETRYCOUNT}_\$COUNT.txt $OURDATA --outname=$WORKDIR/${RETRYCOUNT}_\$COUNT $@
RETVAL=\$?
ls -lah
ls -lah $WORKDIR
if [[ ! \$RETVAL -eq 0 || ! -e $WORKDIR/${RETRYCOUNT}_\$COUNT.root ]]; then
    echo "Failed" >> $WORKDIR/FAILED.${RETRYCOUNT}_\$COUNT
    cat \$INPUTLIST >> $WORKDIR/FAILED.${RETRYCOUNT}_\$COUNT
    # make later hadds bomb
    rm $WORKDIR/${RETRYCOUNT}_\$COUNT.root
    mv $WORKDIR/input_${RETRYCOUNT}_\$COUNT.txt $WORKDIR/failed_input_${RETRYCOUNT}_\$COUNT.txt
else
    mv $WORKDIR/${RETRYCOUNT}_\$COUNT.root $WORKDIR/output_${RETRYCOUNT}_\$COUNT.root
    rm $WORKDIR/FAILED.${RETRYCOUNT}_\$COUNT
fi
rm $WORKDIR/marker_${RETRYCOUNT}_\$COUNT.txt
EOF

rm $WORKDIR/makelock

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
COUNT=0
SPLITCOUNT=0
while [[ -e $WORKDIR/input_$COUNT.txt ]]; do
    COUNT=$((COUNT + 1))
done
while true; do
    FILELIST=$( split_file.sh $USERSLIST 40 $SPLITCOUNT )
    if [[ "X$FILELIST" = 'X' ]]; then
        break
    fi
    echo "$FILELIST" > $WORKDIR/input_$COUNT.txt
    cat << EOF > tempscript.pbs
#!/bin/bash
#PBS -M andrew.m.melo@vanderbilt.edu
#PBS -l nodes=1:ppn=1
#PBS -l mem=1900mb
#PBS -l walltime=9:00:00
#PBS -o $WORKDIR/stdout_$COUNT.txt
#PBS -j oe
#PBS -W group_list=jswhep
#PBS -p $PRIORITY
if [[ ! -e $WORKDIR ]]; then
    mkdir -p $WORKDIR
fi
cd ~
. set-analysis.sh
echo "input list is $WORKDIR/input_$COUNT.txt"
set -x
if [[ -e $WORKDIR/output_$COUNT.root ]]; then
    echo "FAILED OVERWRITE" >> $WORKDIR/FAILED.$COUNT
    cat $WORKDIR/input_$COUNT.txt >> $WORKDIR/FAILED.$COUNT
    exit 1
fi
rm $WORKDIR/$COUNT.root
echo "Started at \$(date)" >> $WORKDIR/FAILED.$COUNT
echo "At dir: \$(pwd)"
ls -lah
time python2.6 shyft_fwlite.py --inputListFile=$WORKDIR/input_$COUNT.txt --sampleName=$SAMPLE $OURDATA --lepType=0 --outname=$WORKDIR/$COUNT $@
RETVAL=\$?
ls -lah
ls -lah $WORKDIR
if [[ ! \$RETVAL -eq 0 || ! -e $WORKDIR/$COUNT.root ]]; then
    echo "Failed" >> $WORKDIR/FAILED.$COUNT
    cat \$INPUTLIST >> $WORKDIR/FAILED.$COUNT
    # make later hadds bomb
    echo "FAILED" > $WORKDIR/$COUNT.root
else
    rm $WORKDIR/FAILED.$COUNT
fi
mv $WORKDIR/$COUNT.root $WORKDIR/output_$COUNT.root
EOF
    qsub tempscript.pbs | tee $WORKDIR/marker_$COUNT.txt
    COUNT=$(( $COUNT + 1 ))
    SPLITCOUNT=$(( SPLITCOUNT + 1 ))
done
rm $WORKDIR/makelock

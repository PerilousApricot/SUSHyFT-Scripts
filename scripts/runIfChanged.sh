#!/bin/bash
# runIfChanged outputFile input1 [input 2] .. -- command <args>
# only executes the command if the input files have changed or if outputFile
# doesn't exist

command -v md5sum &>/dev/null
if [[ $? -ne 0 ]]; then
    echo "ERROR: 'md5sum' not found in \$PATH. $0 requires this tool"
    exit 99
fi

OUTPUTFILE=$1
[[ -d `dirname $OUTPUTFILE`/state ]] || mkdir -p `dirname $OUTPUTFILE`/state
[[ -d `dirname $OUTPUTFILE`/output ]] || mkdir -p `dirname $OUTPUTFILE`/output
#echo "args are $@"
shift
STATEFILE=`dirname $OUTPUTFILE`/state/`basename $OUTPUTFILE`.state
COMMANDOUTPUT=`dirname $OUTPUTFILE`/output/`basename $OUTPUTFILE`.txt
INPUTS=""
while [[ $1 != "--" ]]; do
    INPUTS="$1 $INPUTS"
    shift
done
shift # jump past the --

ARGHASH=$(echo "$@" | sed "s#${SUSHYFT_BASE}##g" | md5sum | awk '{ print $1 }')
CURRSTATE="$(ls -l $INPUTS | sort | md5sum | awk '{ print $1 }')-$ARGHASH"
if [[ -e $STATEFILE && -e $OUTPUTFILE ]]; then
    # don't jump past the "--", we need it for below
    OLDSTATE=$(cat $STATEFILE 2>/dev/null)
    if [[ "$CURRSTATE" == "$OLDSTATE" ]]; then
        exit 0
    else
        echo "State changed, gonna reprocess"
        echo $OLDSTATE
        echo $CURRSTATE
        diff -u <(echo "$OLDSTATE") <(echo "$CURRSTATE")
        [[ -e $OUTPUTFILE ]] && rm $OUTPUTFILE
        [[ -e $STATEFILE ]] && rm $STATEFILE
        [[ -e $COMMANDOUTPUT ]] && rm $COMMANDOUTPUT
    fi
else
    echo "Couldnt find $STATEFILE or $OUTPUTFILE"
fi
[[ -e $OUTPUTFILE ]] && rm $OUTPUTFILE
echo -n $CURRSTATE > $STATEFILE.temp 
echo "Executing $@"
touch $OUTPUTFILE.FAIL
$@  > $COMMANDOUTPUT 2>&1
EXIT_CODE=$?
[[ -e $OUTPUTFILE.FAIL ]] && rm $OUTPUTFILE.FAIL
if [[ $EXIT_CODE -eq 0 ]]; then
    echo "Command successful"
    mv $STATEFILE.temp $STATEFILE
    exit 0
fi
# rut roh
echo "Command exited with code $EXIT_CODE"
touch $OUTPUTFILE.FAIL
echo "FAIL" >> $STATEFILE
exit $EXIT_CODE

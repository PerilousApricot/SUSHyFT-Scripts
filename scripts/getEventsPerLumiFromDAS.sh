#!/bin/bash

# getEventsPerLumiFromDAS.sh [dataset]
# gives a rough count for the numbers of events in each
# lumi for a dataset, useful for figuring out a good job splitting

echo $(( $(getEventCountFromDAS.sh $1) / $(getLumiCountFromDAS.sh $1) ))

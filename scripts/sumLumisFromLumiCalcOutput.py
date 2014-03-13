#!/usr/bin/env python

# sumLumisFromLumiCalcOutput.py [output1] [output2] ..
# pipe in the output from pixelLumiCalc overview -i <json>
# get back out the recorded sum in pb^-1

import re
import sys

total = 0.0
unitLookup = {'fb':1000.0,'pb':1.0,'nb':0.001}
for oneFile in sys.argv[1:]:
    someLines = open(oneFile, 'r').readlines()[-4:-1]
    retval = re.search(r'Recorded\(/(.*)\)', someLines[-3])
    unitScale = unitLookup[retval.group(1)]
    retval = re.search(r'\|.*\|.*\|.*\|\s*(.*)\s*\|', someLines[2])
    total += float(retval.group(1)) * unitScale

print total


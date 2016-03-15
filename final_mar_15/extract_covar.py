#!/usr/bin/env python

import sys
outorder = ['Stop450', 'Top', 'WJets', 'ZJets', 'SingleTop', 'DiBoson']
rowIndex = []
count = 0
for line in sys.stdin.readlines():
    splitline = line.split()
    if not splitline:
        continue
    if not rowIndex:
        for col in outorder:
            rowIndex.append(splitline.index(col) + 1)
        continue
    else:
        shouldWrite = False
        buf = "stat%s lnN " % count
        for col in rowIndex:
            val = float(splitline[col])
            if val != 0.0:
                shouldWrite = True
                buf += "  %s" % ( 1.0 + (val * val) )
            else:
                buf += "  -"
        buf += "  -"
        if shouldWrite:
            print buf
        count += 1


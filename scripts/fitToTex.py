#!/usr/bin/env python

import optparse
import os
import os.path
import sys

parser = optparse.OptionParser()
parser.add_option("-f", "--fit", action="store_true",
                    help="Convert fit result to TeX")
parser.add_option("-c", "--correlation", action="store_true",
                    help="Convert correlation matrix to TeX")
(opts, args) = parser.parse_args()
if not opts.fit and not opts.correlation:
    parser.error("Need to what to output")
elif opts.fit and opts.correlation:
    parser.error("Can only output one type of output at a time")

if not args:
    inFile = sys.stdin
else:
    inFile = open(args[0], 'r')

inFit = False
inCorrelation = False
dataRows = []
for line in inFile.readlines():
    line = line.strip()
    if not line:
        # skip empty lines
        continue
    if line.startswith("Fit Results:"):
        inFit = True
        if opts.fit:
            headerRows = [
                            "\\begin{tabular}{l|r}",
                            "Quantity & Fit Factor \\\\",
                            "\\hline",
                         ]
        continue
    elif line.startswith("Correlation Matrix:"):
        inFit = False
        inCorrelation = True
        if opts.correlation:
            headerRows = []
            dataRows = []
            correlationHeaders = [' ']
        continue
    if (inFit and not opts.fit) or (inCorrelation and not opts.correlation):
        continue
    if not inFit and not inCorrelation:
        continue
    if opts.fit and inFit:
        splitFit = line.split()
        if splitFit[4] == "(fixed)":
            continue
        curr = "%s & $%0.2f^{%+0.2f}_{%+0.2f}$ \\\\" % \
                                                    (splitFit[1].replace('_','\_'),
                                                    float(splitFit[3]),
                                                    float(splitFit[4]),
                                                    float(splitFit[5]))
        dataRows.append(curr)
    elif opts.correlation and inCorrelation:
        splitFit = line.split()
        splitFit[1] = splitFit[1].replace('_','\_')
        correlationHeaders.append(splitFit[1])
        joinArray = [splitFit[1]]
        joinArray.extend(splitFit[3:])
        curr = " & ".join(joinArray) + "\\\\"
        dataRows.append(curr)

if opts.correlation:
    lineCount = len(dataRows)
    tabular = "\\begin{tabular}{r|%s}" % ("r " * lineCount)
    titles = " & ".join(correlationHeaders) + "\\\\"
    headerRows = [ tabular, titles, "\\hline" ]

print "\n".join(headerRows)
print "\n".join(dataRows)
print "\\end{tabular}"

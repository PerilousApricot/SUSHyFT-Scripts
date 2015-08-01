#!/usr/bin/env python

import glob
import re
import sys
from SHyFT.ROOTWrap import ROOT

import optparse

parser = optparse.OptionParser()
parser.add_option('-v', '--verbose',action='store_true')
parser.add_option('-d', '--debug',action='store_true')
parser.add_option('-r', '--raw', action='store_true')
parser.add_option('--groupBy', action='append', default=[])
(options, args) = parser.parse_args()
verbose = options.verbose
debug = options.debug

if len(args) == 0:
    sys.stderr.write("Usage: %s [--groupBy=regex] file_glob:plot_regex ...")
    sys.exit(1)

plotsToPrint = []
# strong reference the TFile to keep ROOT from reaping it
fileRefs = []
for arg in args:
    argSplit = arg.split(':')
    if len(argSplit) == 1:
        fileGlob = arg
        plotRegex = '.*'
    elif len(argSplit) == 2:
        fileGlob = argSplit[0]
        plotRegex = argSplit[1]
    fileList = glob.glob(fileGlob)
    plotRegex = re.compile(plotRegex)
    for oneFile in fileList:
        if debug:
            print "Examining %s" % oneFile
        rootFile = ROOT.TFile(oneFile,'READONLY')
        ROOT.gDirectory.Cd("")
        fileRefs.append(rootFile)
        for key in rootFile.GetListOfKeys():
            keyString = key.GetName()
            if plotRegex.search(keyString) != None:
                if debug:
                    print "  Examining %s" % keyString
                plotsToPrint.append((keyString, rootFile.Get(keyString)))

totalSum = 0.0
maxKeyLen = 0
for key, _ in plotsToPrint:
    maxKeyLen = max(maxKeyLen, len(key))


def formatIntegral(integral, raw):
    if raw:
        return "{0:.2f}".format(integral)
    else:
        return "{0:.2E}".format(integral)

for key, plot in plotsToPrint:
    spaces = " " * (maxKeyLen - len(key))
    integral = plot.Integral()
    totalSum += integral
    if verbose:
        print "{0}: {1}{2:.2E}".format(key, spaces, integral)
if verbose:
    print "=" * (maxKeyLen + 9)
    print "Total: " + formatIntegral(totalSum, options.raw)
else:
    print formatIntegral(totalSum, options.raw)

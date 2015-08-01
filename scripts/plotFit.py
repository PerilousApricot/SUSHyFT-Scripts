#!/usr/bin/env python

from SHyFT.WebifyHistograms import dumpOutput
import sys
if (len(sys.argv) != 3):
    print "Usage: %s <input file> <output prefix>"
    sys.exit(1)

dumpOutput(sys.argv[1], sys.argv[2])

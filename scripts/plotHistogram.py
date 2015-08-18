#!/usr/bin/env python

from SHyFT.WebifyHistograms import dumpStitched
import sys
if (len(sys.argv) != 3):
    print "Usage: %s <input file> <output prefix>" % sys.argv[0]
    sys.exit(1)

dumpStitched(sys.argv[1], sys.argv[2])

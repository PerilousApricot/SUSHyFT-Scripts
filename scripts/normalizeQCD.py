#!/usr/bin/env python

from SHyFT.ROOTWrap import ROOT
import sys

if len(sys.argv) != 3:
    print "Usage: %s <input> <output>" % sys.argv[0]

TFile = ROOT.TFile
inputFile = TFile(sys.argv[1])
outputFile = TFile(sys.argv[2], "RECREATE")

for key in inputFile.GetListOfKeys():
    keyString = key.GetName()
    if not keyString.startswith('QCDpre'):
        inputFile.Get(keyString).Write()
    else:
        taggedKey = keyString.replace('QCDpre', 'QCD')
        taggedHist = inputFile.Get(taggedKey)
        preHist = inputFile.Get(keyString)
        if preHist.Integral() != 0.0:
            targetEvents = taggedHist.Integral()
            preHist.Scale(targetEvents/preHist.Integral())
        preHist.Write()

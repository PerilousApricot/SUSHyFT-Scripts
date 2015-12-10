#!/usr/bin/env python

from SHyFT.ROOTWrap import ROOT
import sys

if len(sys.argv) != 4:
    print "Usage: %s <input> <comparison> <output>" % sys.argv[0]

TFile = ROOT.TFile
ROOT.TH1.AddDirectory(False)
inputFile = TFile(sys.argv[1])
compareFile = TFile(sys.argv[2])
outputFile = TFile(sys.argv[3], "RECREATE")

qcdDict = {}
qcdNorm = {}
qcdOut = {}
for key in inputFile.GetListOfKeys():
    keyString = key.GetName()
    temp = inputFile.Get(keyString).Clone()
    if not keyString.startswith('QCD_'):
        temp.SetDirectory(outputFile)
        temp.Write()
    else:
        qcdDict[keyString] = temp.Clone()
        qcdNorm[keyString] = temp.Integral()
        qcdOut[keyString] = temp

for k1 in sorted(qcdOut.keys()):
    prefix = "_".join(k1.split("_")[0:3])
    for k2 in sorted(qcdDict.keys()):
        if k2.startswith(prefix) and k1 != k2:
            qcdOut[k1].Add(qcdDict[k2])
    qcdOut[k1].Scale(qcdNorm[k1]/qcdOut[k1].Integral())
    qcdOut[k1].SetDirectory(outputFile)
outputFile.Write()

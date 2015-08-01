#! /usr/bin/env python
import os
import glob
import math
import copy
import sys
import pprint

from optparse import OptionParser

parser = OptionParser()

# Import everything from ROOT
oldargv = sys.argv[:]
sys.argv = []
import ROOT
ROOT.gROOT.Macro("~/rootlogon.C")
sys.argv = oldargv[:]

mcFile = ROOT.TFile()
mcFile = mcFile.Open("root://cmsxrootd.fnal.gov//store/user/meloam/S10MC_PUFile.root")
dataFile = ROOT.TFile()
dataFile = dataFile.Open("root://cmsxrootd.fnal.gov//store/user/meloam/DataPUFile_Full2012.root")
mcHist = mcFile.Get("analyzeHiMassTau/NVertices_0")
dataHist = dataFile.Get("analyzeHiMassTau/NVertices_0")

dataHist.Divide(mcHist)


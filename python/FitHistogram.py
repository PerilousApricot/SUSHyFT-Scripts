import sys
oldargv = sys.argv[:]
sys.argv = [] 
import ROOT 
ROOT.gROOT.Macro("~/rootlogon.C")
sys.argv = oldargv[:]

class FitHistogram:
    """ Reads and parses the output from the fitter and stores jet/tag/tau plots
        for later plotting """
    def load(self, filename):
        data = ROOT.TFile(filename)


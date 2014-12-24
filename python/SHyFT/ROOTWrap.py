"""
    Wrap around PyROOT's weird behavior
"""
import sys
oldargs = sys.argv[:]
sys.argv = sys.argv[0:1]
import ROOT
# FWLite on 5_3_X does the wrong thing for importing ROOT things
if ROOT.gROOT.GetVersion() == '5.32/00' and sys.platform.startswith('darwin'):
    ROOT.gSystem.Load("libFWCoreFWLite")
ROOT.gROOT.SetBatch(True)
ROOT.gErrorIgnoreLevel=1001
sys.argv = oldargs[:]

__all__ = ['ROOT']

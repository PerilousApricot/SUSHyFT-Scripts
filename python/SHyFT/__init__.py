"""
    Wrap around PyROOT's weird behavior
"""
import sys
oldargs = sys.argv[:]
sys.argv = sys.argv[0:1]
import ROOT
ROOT.gROOT.SetBatch(True)
sys.argv = oldargs[:]

__all__ = ['ROOT']

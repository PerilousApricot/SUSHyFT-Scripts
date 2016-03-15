#!/usr/bin/env python

from array import array
import math
from SHyFT.ROOTWrap import ROOT
import sys

xvals = []
yvals = []

with open(sys.argv[1]) as f:
    for line in f:
        line = line.rstrip('\n')
        splitted = line.split(' ')
        if (len(splitted) == 2):
            xvals.append(float(splitted[0]))
            yvals.append(float(splitted[1]))
c = ROOT.TCanvas("c","Log likelihood scan", 200,10, 700, 500)
g = ROOT.TGraph(len(xvals), array('d', xvals), array('d', yvals))
f = ROOT.TF1("fun", "[2] * x * x + [1] * x + [0]")
h = ROOT.TF1("fun", "[2] * (x - [0])^2 / ([1] ^ 2)")
g.Fit(f)
g.Draw("AL")
g.Fit(h)
g.Draw("A")
c.Update()
c.Print("fitpara.pdf")
print len(xvals)
print len(yvals)
peak = f.GetMinimum(xvals[0], xvals[-1], 1E-10,100000)
maxx = f.GetMinimumX(xvals[0], xvals[-1], 1E-10,100000)
print "f(%.4f) = %.4f" % (maxx, peak)
derivative2 = f.Derivative2(maxx)
print "95CL = %.4f" % (1.96 * math.sqrt(1/derivative2))

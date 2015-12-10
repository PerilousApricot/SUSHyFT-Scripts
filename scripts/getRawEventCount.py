#!/usr/bin/env python

import json
import sys
from SHyFT.ROOTWrap import ROOT

f = ROOT.TFile(sys.argv[1])

ret = {}

for rootKey in f.GetListOfKeys():
    key = rootKey.GetName()
    if not key.startswith('MET_'):
        continue
    integral = f.Get(key).Integral()
    shortKey = key[4:-2]
    if shortKey == '0j_0b_0t':
        continue
    ret[shortKey] = ret.get(shortKey, 0) + integral
print json.dumps(ret, sort_keys=True, indent=4)

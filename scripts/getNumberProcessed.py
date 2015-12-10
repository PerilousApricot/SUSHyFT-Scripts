#!/usr/bin/env python

import json
import sys

try:
    bare = sys.argv[1][:-5] # .root
    edn = open(bare + "_edntuple.txt", 'r').read()
    edn_processed, edn_passed = edn.split(' ')
    fwlite = open(bare + "_fwlite.txt", 'r').read()
except:
    edn_passed = 1
    edn_processed = 0
    fwlite = 0

ret = { 'edn_passed' : float(edn_passed),
        'edn_processed' : float(edn_processed),
        'fwlite_processed' : float(fwlite),
        'n_processed' : float(fwlite) * float(edn_processed) / float(edn_passed)
        }
print json.dumps(ret)

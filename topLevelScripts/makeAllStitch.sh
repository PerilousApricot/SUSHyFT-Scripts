#!/bin/bash
ls systs_8TeV_ttbar_noTau/*.cfg | parallel -n 1 -P 10 python stitch.py stitchConfig_8TeV_ttbar_noTau.cfg

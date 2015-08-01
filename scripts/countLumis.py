#!/usr/bin/env python

import sys
import json
if len(sys.argv) == 1:
    inputList = [sys.stdin]
else:
    def openHandler(path):
        if path == '-':
            return sys.stdin
        else:
            return open(path, 'r')
    inputList = [openHandler(x) for x in sys.argv[1:]]

lumiCount = 0
for input in inputList:
    result = json.load(input)
    if result['status'] != 'ok':
        raise RuntimeError, "Got bad result from DAS"
    lumiCount = 0
    for resultRow in result['data']:
        for lumiRow in resultRow['lumi'][0]['number']:
            lumiCount += lumiRow[1] - lumiRow[0] + 1
print lumiCount

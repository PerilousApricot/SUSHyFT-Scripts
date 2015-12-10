#!/usr/bin/env python

from xml.dom import minidom
import sys

inEventSum = 0
outEventSum = 0

for oneFile in sys.argv[1:]:
    doc = minidom.parse(oneFile)

    fjr = doc.getElementsByTagName("FrameworkJobReport")[0]
    outEvents = doc.getElementsByTagName("TotalEvents")
    inEvents = doc.getElementsByTagName("EventsRead")

    if fjr.getAttribute('Status') == 'Success':
        for inFile in inEvents:
            inEventSum += int(inFile.firstChild.data)
        for outFile in outEvents:
            outEventSum += int(outFile.firstChild.data)

print "%s %s" % (inEventSum, outEventSum)

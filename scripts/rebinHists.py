#!/usr/bin/env python2.6

import os
import re
import sys
oldArgv = sys.argv[:]
sys.argv = [oldArgv[0], '-b']
import ROOT
sys.argv = oldArgv[:]

from optparse import OptionParser
parser = OptionParser()
parser.add_option('--tagCheck', action='store_true',
              default=False, help="Check if the binning strategy is added")
parser.add_option('--tagMode', metavar='F', type='string', action='store',
              dest='tagMode',
              help='Which rebinning pattern should we use')
parser.add_option('--outDir', metavar='F', type='string', action='store',
              dest='outDir',
              help='What output directory should we use')
parser.add_option('--qcd', action='store_true',
              help='Do pretagged QCD distributions too')
(options, args) = parser.parse_args()

def bin_ttbar_notau(inputTitle):
    matches = re.search(r"(.*)_(\d)j_(\d)t(_[bcq])?", inputTitle)
    if matches == None:
        if inputTitle.find('Tau') == -1:
            pass
            # print "rejected %s" % inputTitle
        return None
    name, jets, tags, postfix = matches.group(1,2,3,4)
    jets = int(jets)
    tags = int(tags)
    if jets == 0 or tags == 0:
        return None
    if not postfix:
        postfix = ""
    if jets >= 5:
        jets = 5
    if tags >= 2:
        tags = 2
    result = ["%s_%sj_%st%s" % (name, jets, tags, postfix)]
    # make a pretag?
    if inputTitle.lower().find('qcd') != -1:
        for tag in ('0','1','2'):
            result.append("%s_pretag_%sj_%st%s" % (name, jets, tag, postfix))
    return result

def bin_st_0tau(inputTitle):
    matches = re.search(r"(.*)_(\d)j_(\d)b_(\d)t(_[bcq])?", inputTitle)
    if matches == None:
        return None
    name, jets, tags, taus, postfix = matches.group(1,2,3,4,5)
    jets = int(jets)
    tags = int(tags)
    taus = int(taus)
    if taus != 0:
        return None
    if not postfix:
        postfix = ""
    if jets >= 5:
        jets = 5
    if tags >= 2:
        tags = 2
    result = ["%s_%sj_%sb_%st%s" % (name, jets, tags, taus, postfix)]
    return result


def bin_st_eq1tau(inputTitle):
    matches = re.search(r"(.*)_(\d)j_(\d)b_(\d)t(_[bcq])?", inputTitle)
    if matches == None:
        return None
    name, jets, tags, taus, postfix = matches.group(1,2,3,4,5)
    jets = int(jets)
    tags = int(tags)
    taus = int(taus)
    if taus != 1:
        return None
    if not postfix:
        postfix = ""
    if jets >= 5:
        jets = 5
    if tags >= 2:
        tags = 2
    result = ["%s_%sj_%sb_%st%s" % (name, jets, tags, taus, postfix)]
    return result

def bin_st_gt1tau(inputTitle):
    matches = re.search(r"(.*)_(\d)j_(\d)b_(\d)t(_[bcq])?", inputTitle)
    if matches == None:
        return None
    name, jets, tags, taus, postfix = matches.group(1,2,3,4,5)
    jets = int(jets)
    tags = int(tags)
    taus = int(taus)
    if taus == 0:
        return None
    if not postfix:
        postfix = ""
    if jets >= 5:
        jets = 5
    if tags >= 2:
        tags = 2
    taus = 1
    result = ["%s_%sj_%sb_%st%s" % (name, jets, tags, taus, postfix)]
    return result


def bin_st_gt2tau(inputTitle):
    matches = re.search(r"(.*)_(\d)j_(\d)b_(\d)t(_[bcq])?", inputTitle)
    if matches == None:
        return None
    name, jets, tags, taus, postfix = matches.group(1,2,3,4,5)
    jets = int(jets)
    tags = int(tags)
    taus = int(taus)
    if taus < 2:
        return None
    if not postfix:
        postfix = ""
    if jets >= 5:
        jets = 5
    if tags >= 2:
        tags = 2
    taus = 2
    result = ["%s_%sj_%sb_%st%s" % (name, jets, tags, taus, postfix)]
    return result


def bin_ttbar_notau0jet(inputTitle):
    matches = re.search(r"(.*)_(\d)j_(\d)b_\dt(_[bcq])?", inputTitle)
    if matches == None:
        if inputTitle.find('Tau') == -1:
            pass
            # print "rejected %s" % inputTitle
        return None
    name, jets, tags, postfix = matches.group(1,2,3,4)
    jets = int(jets)
    tags = int(tags)
    if not postfix:
        postfix = ""
    if jets >= 5:
        jets = 5
    if tags >= 2:
        tags = 2
    result = ["%s_%sj_%st%s" % (name, jets, tags, postfix)]
    # make a pretag?
    if inputTitle.lower().find('qcd') != -1:
        for tag in ('0','1','2'):
            result.append("%s_pretag_%sj_%st%s" % (name, jets, tag, postfix))
    return result

def bin_012345jet_012tag_01tau(inputTitle):
    matches = re.search(r"(.*)_Tau_(\d)j_(\d)b_(\d)t(_[bcq])?", inputTitle)
    if matches == None:
        return None
    name, jets, tags, taus, postfix = matches.group(1,2,3,4,5)
    jets = int(jets)
    tags = int(tags)
    if not postfix:
        postfix = ""
    if jets >= 5:
        jets = 5
    if tags >= 2:
        tags = 2
    if taus >= 1:
        taus = 1
    result = ["%s_%sj_%sb_%st%s" % (name, jets, tags, taus, postfix)]
    # make a pretag?
    if inputTitle.lower().find('qcd') != -1:
        for tag in ('0','1','2'):
            result.append("%s_pretag_%sj_%sb_%st%s" % (name, jets, tag, taus, postfix))
    return result

def bin_st_nominal(inputTitle):
    global options
    matches = re.search(r"(.*)_(\d)j_(\d)b_(\d)t(_[bcq])?", inputTitle)
    if matches == None:
        return None
    name, jets, tags, taus, postfix = matches.group(1,2,3,4,5)
    jets = int(jets)
    tags = int(tags)
    taus = int(taus)
    if not postfix:
        postfix = ""
    if jets >= 5:
        jets = 5
    if tags >= 2:
        tags = 2
    if taus >= 1:
        taus = 1
    result = ["%s_%sj_%sb_%st%s" % (name, jets, tags, taus, postfix)]
    if options.qcd:
        for tags in (0,1,2):
            for taus in (0,1):
                if (tags + taus) > jets:
                    continue
                result.append("%spre_%sj_%sb_%st%s" %
                                (name, jets, tags, taus, postfix))
    return result

def bin_onebin(inputTitle):
    matches = re.search(r"(.*)_(\d)j_(\d)b_(\d)t(_[bcq])?", inputTitle)
    if matches == None:
        return None
    name, postfix = matches.group(1,5)
    if not postfix:
        postfix = ""
    result = ["%s_0j_0b_0t%s" % (name, postfix)]
    return result

def getBinFunction(tagMode):
    if tagMode == 'ttbar_notau':
        return bin_ttbar_notau
    elif tagMode == 'tt-012tag-1tau-btag':
        return bin_012345jet_012tag_01tau
    elif tagMode in ['ttbar_notau0jet', 'ttbar_1jet0b', 'ttbar_1jetwnob','ttbar_notauzerojet'] or tagMode.startswith('tt-012tag'):
        return bin_ttbar_notau0jet
    elif tagMode == 'st-0tau':
        return bin_st_0tau
    elif tagMode == 'st-eq1tau':
        return bin_st_eq1tau
    elif tagMode == 'st-gt2tau':
        return bin_st_gt2tau
    elif tagMode == 'st-gt1tau':
        return bin_st_gt1tau
    elif tagMode == 'st-nominal':
        return bin_st_nominal
    elif tagMode == 'onebin':
        return bin_onebin
    else:
        raise RuntimeError, "Unknown binning strategy, (%s)" % (tagMode)

if options.tagMode.startswith('test_'):
        options.tagMode = options.tagMode[len('test_'):]

if options.tagCheck:
    try:
        getBinFunction(options.tagMode)
        sys.exit(0)
    except RuntimeError:
        print "Unsupported config: %s" % options.tagMode
        sys.exit(1)

for oneFile in args:
    additionDict = {}
    print "Processing %s" % oneFile
    inFile = ROOT.TFile(oneFile)
    if not inFile or inFile.IsZombie():
        raise RuntimeError, "missing file"
    outFileName = os.path.join(options.outDir, os.path.basename(oneFile))
    outFile = ROOT.TFile(outFileName, "RECREATE")
    if not outFile:
        raise RuntimeError, "Missing file"
    print "  Outputting to %s" % outFileName
    outDir = outFile.GetDirectory('')
    missingHists = []
    histList     = []
    for key in inFile.GetListOfKeys():
        keyString = key.GetName()
        print "Examining: %s" % keyString
        binFunc = getBinFunction(options.tagMode)
        outputs = binFunc(keyString)
        if keyString == 'nEvents':
            outputs = ['nEvents']
        elif outputs == None:
            continue
        theirHist = inFile.Get(keyString)
        if not theirHist:
            missingHists.append(keyString)
            print "    **How is it possible that the histogram was missing?"
            continue

        for result in outputs:
            if not outFile.Get(result):
                thisHist  = theirHist.Clone()
                thisHist.SetName(result)
                thisHist.SetDirectory(outDir)
                histList.append(thisHist)
            else:
                oldHist = outFile.Get(result)
                currIntegral = oldHist.Integral()
                oldHist.Add(theirHist)
            additionDict.setdefault(result, [])
            additionDict[result].append(keyString)
    for hist in histList:
        hist.Write()
    outFile.Close()
    inFile.Close()
    print "  Outputs were:"
    for k in additionDict:
        print "  * %s" % k
        for val in additionDict[k]:
            print "    * %s" % val
    testFile = ROOT.TFile(outFileName)
    if not testFile:
        raise RuntimeError, "couldn't open output"
    keyList = {}
    for k in testFile.GetListOfKeys():
        keyList[k.GetName()] = 1

    for k in additionDict:
        if not k in keyList:
            raise RuntimeError, "We wanted this hist (%s) but it didn't show up" % k

    if missingHists:
        print "  Missing these histograms :(\n%s" % "\n  ".join(missingHists)

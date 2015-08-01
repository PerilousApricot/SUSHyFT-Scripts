#!/usr/bin/env python

import array
import itertools
import json
import os
import os.path
import sys
from SHyFT.Plot import StackedPlot
from SHyFT.ROOTWrap import ROOT
TFile = ROOT.TFile

# TODO fix this
shyftBase = os.getenv('SHYFT_BASE')
shyftMode = os.getenv('SHYFT_MODE')
webPath = os.path.join(shyftBase, 'web', shyftMode)
if not os.path.exists(webPath):
    os.makedirs(webPath)

inputFile = os.path.join(shyftBase, 'output', shyftMode, 'central_nominal_lum1.0')
outputFile = "%s_split.root" % inputFile
templateFile = inputFile + "_templates.root"
metaFile = inputFile + "_meta.json"
temp = TFile(templateFile)
output = TFile(outputFile, "RECREATE")
output.cd()
meta = json.loads(open(metaFile).read())
dataHist = temp.Get('newdata')
mcHists = {'Data':dataHist}
for key in temp.GetListOfKeys():
    keyString = key.GetName()
    if keyString.endswith('_updated'):
        mcHists[keyString.split('_')[0]] = temp.Get(keyString)

reverseIndex = dict((v, k) for (k, v) in meta['groupIndexMap'].items())
lowerEdgeIdx = 0
for (binName, binIndex) in meta['groupIndexMap'].items():
    newBins = meta['numBinsVec'][binIndex]
    lowerBin = meta['lowerEdgeBinVec'][binIndex]
    upperBin = meta['upperEdgeBinVec'][binIndex]
    binVec = [float(x) for x in meta['binLowerEdges'][lowerBin - 1:upperBin]]
    binArray = array.array('f', binVec)
    for mc in mcHists:
        newName = "%s%s" % (mc, binName)
        # TODO propagate xmin/xmax from the fit
        newHist = ROOT.TH1F(newName, newName, newBins - 1, binArray)
        for histIndex in range(newBins):
            oldContent = mcHists[mc].GetBinContent(lowerBin + histIndex)
            oldError = mcHists[mc].GetBinError(lowerBin + histIndex)
            newHist.SetBinContent(histIndex, oldContent)
            newHist.SetBinError(histIndex, oldError)
        newHist.Write()
    lowerEdgeIdx += newBins
output.Write()
temp.Close()
temp = output
discList = []
for key in temp.GetListOfKeys():
    keyString = key.GetName()
    keySplit = keyString.split('_')
    currDisc = "_".join(keySplit[2:])
    if currDisc == 'svm':
        continue
    if not currDisc in discList:
        discList.append(currDisc)

discList.sort()
# split the histograms out, so plot them now
defaultColors = {'SingleTop' : ROOT.kCyan,
                'SingleTT' : ROOT.kCyan - 3,
                 'SingleTS' : ROOT.kCyan - 2,
                 'SingleTTW' : ROOT.kCyan - 1,
                 'SingleTbarT' : ROOT.kCyan + 1,
                 'SingleTbarS' : ROOT.kCyan + 2,
                 'SingleTbarTW' : ROOT.kCyan + 3,
                 'Wqq' : ROOT.kGreen + 1,
                 'Wcx' : ROOT.kGreen + 2,
                 'Wbx' : ROOT.kGreen + 3,
                 'WZ' : ROOT.kYellow +3,
                 'WW' : ROOT.kYellow -6,
                 'DiBoson' : ROOT.kOrange,
                 'Top' : ROOT.kRed,
                 'Zinv' : ROOT.kBlue-3,
                 'ZJets' : ROOT.kBlue,
                 'ZZ' : ROOT.kPink -6,
                 'Stop450' : ROOT.kYellow,
                 'QCDpre' : ROOT.kMagenta,
                 'QCD' : ROOT.kMagenta}
xlabelsPerDisc = {'lepPt' : 'GeV/c',
                  'MET' : 'GeV',
                  'hT' : 'GeV',
                  'std' : 'GeV/c',
                  'stdt' : 'GeV/c',
                  'sumEt' : 'GeV',
                  'wrp' : 'rad',
                  'wMT' : 'GeV/c^{2}',
                  'hT' : 'GeV',
                  }
sampleToCategory = { 'WZ' : 'Diboson',
                     'WW' : 'Diboson',
                     'ZZ' : 'Diboson',
                    'SingleTT' : 'SingleTop',
                    'SingleTS' : 'SingleTop',
                    'SingleTTW' : 'SingleTop',
                    'SingleTbarT' : 'SingleTop',
                    'SingleTbarS' : 'SingleTop',
                    'SingleTbarTW' : 'SingleTop',
                    'Zinv' : 'ZJets',
                    'ZJets' : 'ZJets' }

def iterateJetBottomTau():
    return itertools.product((0,1,2,3,4,5),(0,1,2),(0,1,2))

integralLookup = []
for key in temp.GetListOfKeys():
    keyString = key.GetName()
    integralLookup.append((keyString, temp.Get(keyString).Integral()))

with open(os.path.join(webPath, "fitoutput.html"),'w+') as idx:
    idx.write("<html><head><title>Fit Results</title></head><body><h1>SHyFT Fit Results</h1>")
    sampleCounts = {}
    # FIXME: This should really really be automagic
    for njet, nbjet, ntau in iterateJetBottomTau():
        if (nbjet + ntau) > njet:
            continue
        if not njet in sampleCounts:
            sampleCounts[njet] = {}
        if not nbjet in sampleCounts[njet]:
            sampleCounts[njet][nbjet] = {}
        if not ntau in sampleCounts[njet][nbjet]:
            sampleCounts[njet][nbjet][ntau] = {}

        plot = StackedPlot()
        # FIXME should have serialization/deserialization fixed by now
        targetSuffix = "_%sj_%sb_%st" % (njet, nbjet, ntau)
        shouldSave = False
        sizeListing = []
        def customCompare(val):
            return -1*val[1]
        foundBin = False
        for keyString,_ in sorted(integralLookup, key=customCompare):
            sampleString = keyString.split('_')[0]
            if keyString.endswith(targetSuffix):
                foundBin = True
                hist = temp.Get(keyString)
                if hist.Integral() != 0:
                    shouldSave = True
                color = defaultColors.get(sampleString, None)
                currSample = keyString.split('_')[0]
                plot.addQuantity(currSample, temp.Get(keyString), color = color)
                tableCategory = sampleToCategory.get(sampleString, sampleString)
                sampleCounts[njet][nbjet][ntau][tableCategory] = \
                        sampleCounts[njet][nbjet][ntau].get(tableCategory, 0) + \
                        temp.Get(keyString).Integral()
                disc = keyString.split('_')[1]
        if not foundBin:
            print "Got nothing for %s? (probably okay)" % targetSuffix
            continue
        if disc in xlabelsPerDisc:
            plot.xAxisTitle = xlabelsPerDisc[disc]
        plot.title = "%s (%sj, %sb, %st)" % (disc, njet, nbjet, ntau)
        if shouldSave:
            target = os.path.join(webPath,'fit%s' % targetSuffix)
            plot.draw(target + ".svg")
            plot.draw(target + ".pdf")
            plot.draw(target + ".png")
            idx.write('<img src="fit%s.svg" alt="%s" />' % (targetSuffix, plot.title))
        
    idx.write('<table><tr><th>Bin</th><th>Data</th><th>Total Pred</th><th>SF</th>')
    headers = {}
    totalPred = {}
    sampleSum = {}
    allPredictions = 0
    for njet in sampleCounts:
        totalPred[njet] = {}
        for nbjet in sampleCounts[njet]:
            totalPred[njet][nbjet] = {}
            for ntau in sampleCounts[njet][nbjet]:
                totalPred[njet][nbjet][ntau] = 0
                for sample in sampleCounts[njet][nbjet][ntau]:
                    sampleSum[sample] = sampleSum.get(sample, 0) + sampleCounts[njet][nbjet][ntau][sample]
                    if sample != 'Data':
                        headers[sample] = 1
                        totalPred[njet][nbjet][ntau] += sampleCounts[njet][nbjet][ntau][sample]
                        allPredictions += sampleCounts[njet][nbjet][ntau][sample]
    headerList = sorted(headers.keys())
    for header in headerList:
        idx.write('<th>%s</th>' % header)
    idx.write('</tr>\n')
    for njet in sorted(sampleCounts):
        for nbjet in sorted(sampleCounts[njet]):
            for ntau in sorted(sampleCounts[njet][nbjet]):
                if sampleCounts[njet][nbjet][ntau] == {}:
                    continue
                if totalPred[njet][nbjet][ntau] > 0:
                    frac = (sampleCounts[njet][nbjet][ntau]['Data']/totalPred[njet][nbjet][ntau])
                else:
                    frac = 0.0
                idx.write('<tr><th>%sj_%sb_%st</th><td>%.2e</td><td>%.2e</td><td>%.2f</td>' %\
                                (njet,
                                    nbjet,
                                    ntau,
                                    sampleCounts[njet][nbjet][ntau]['Data'],
                                    totalPred[njet][nbjet][ntau], frac))
                for sample in headerList:
                    idx.write('<td>%.2e</td>' % sampleCounts[njet][nbjet][ntau].get(sample, 0))
                idx.write('</tr>\n')
    if allPredictions > 0.0:
        idx.write('<tr><th>Total</th><th>%.2e</th><th>%.2e</th><th>%.2f</th>' % (sampleSum['Data'], allPredictions, sampleSum['Data']/allPredictions))
    else:
        idx.write('<tr><th>Total</th><th>%.2e</th><th>%.2e</th><th>INF</th>' % (sampleSum['Data'], allPredictions))
    for header in headerList:
        idx.write('<th>%.2e</th>' % sampleSum[header])
    idx.write('</tr></table>')
    idx.write("</body></html>")

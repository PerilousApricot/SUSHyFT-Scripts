#!/usr/bin/env python

import pprint
import itertools
import os
import os.path
from SHyFT.Plot import StackedPlot
from SHyFT.ROOTWrap import ROOT
TFile = ROOT.TFile

# TODO fix this
shyftBase = os.getenv('SHYFT_BASE')
shyftMode = os.getenv('SHYFT_MODE')
webPath = os.path.join(shyftBase, 'web', shyftMode)
if not os.path.exists(webPath):
    os.makedirs(webPath)

temp = TFile('data/auto_copyhist/%s/central_nominal.root' % shyftMode)
discList = []
for key in temp.GetListOfKeys():
    keyString = key.GetName()
    keySplit = keyString.split('_')
    currDisc = keySplit[1]
    if currDisc == 'svm':
        continue
    if not currDisc in discList:
        discList.append(currDisc)
        print "loading %s" % currDisc

defaultColors = {'SingleTop' : ROOT.kCyan,
                'SingleTT' : ROOT.kCyan - 3,
                 'SingleTS' : ROOT.kCyan - 2,
                 'SingleTTW' : ROOT.kCyan - 1,
                 'SingleTbarT' : ROOT.kCyan + 1,
                 'SingleTbarS' : ROOT.kCyan + 2,
                 'SingleTbarTW' : ROOT.kCyan + 3,
                 'WJets' : ROOT.kGreen + 1,
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


def dumpStitched(filename, temp, usePreQCD = False, combineWJets = False): 
    with open(os.path.join(webPath, "%s.html" % filename),'w+') as idx:
        idx.write("<html><head><title>Stitched Results</title></head><body><h1>SHyFT stitched input (%s)</h1>" %filename)
        for disc in discList:
            sampleCounts = {}
            idx.write("<h2>%s</h2>" % disc)
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
                if disc in xlabelsPerDisc:
                    plot.xAxisTitle = xlabelsPerDisc[disc]
                # FIXME should have serialization/deserialization fixed by now
                targetSuffix = "_%s_%sj_%sb_%st" % (disc, njet, nbjet, ntau)
                shouldSave = False
                sizeListing = []
                def customCompare(val):
                    return -1*val[1]
                for keyString,_ in sorted(integralLookup, key=customCompare, reverse=True):
                    sampleString = keyString.split('_')[0]
                    if sampleString == "QCDpre" and not usePreQCD:
                        continue
                    elif sampleString == "QCD" and usePreQCD:
                        continue
                    if sampleString in ("Wbx","Wcx","Wqq") and combineWJets:
                        continue
                    elif sampleString == "WJets" and not combineWJets:
                        continue

                    if keyString.endswith(targetSuffix):
                        hist = temp.Get(keyString)
                        if hist.Integral() != 0:
                            shouldSave = True
                        color = defaultColors.get(sampleString, None)
                        plot.addQuantity(keyString, temp.Get(keyString), color = color)
                        tableCategory = sampleToCategory.get(sampleString, sampleString)
                        sampleCounts[njet][nbjet][ntau][tableCategory] = \
                                sampleCounts[njet][nbjet][ntau].get(tableCategory, 0) + \
                                temp.Get(keyString).Integral()
                plot.title = "%s (%sj, %sb, %st)" % (disc, njet, nbjet, ntau)
                if shouldSave:
                    targetReal = os.path.join(webPath,'%s_%s' % (filename, targetSuffix))
                    targetNorm = os.path.join(webPath,'%s_%s_norm' % (filename, targetSuffix))
                    plot.draw(targetNorm + ".svg", nostack=True)
                    plot.draw(targetNorm + ".png", nostack=True)
                    plot.draw(targetReal + ".svg")
                    plot.draw(targetReal + ".png")
                    idx.write('<img src="%s_%s.svg" alt="%s" />' % (filename, targetSuffix, plot.title))
                    idx.write('<img src="%s_%s_norm.svg" alt="%s" />' % (filename, targetSuffix, plot.title))
            idx.write('<table><tr><th>%s</th><th>Data</th><th>Total Pred</th><th>SF</th>' % disc)
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
                        if not 'Data' in sampleCounts[njet][nbjet][ntau]:
                            continue
                        if totalPred[njet][nbjet][ntau] > 0 and 'Data' in sampleCounts[njet][nbjet][ntau]:
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
                pass
                #idx.write('<tr><th>Total</th><th>%.2e</th><th>%.2e</th><th>INF</th>' % (sampleSum['Data'], allPredictions))
            for header in headerList:
                idx.write('<th>%.2e</th>' % sampleSum[header])
            idx.write('</tr></table>')
        idx.write("</body></html>")

#temp = TFile('data/auto_copyhist/%s/metfit.root' % shyftMode)
#dumpStitched("metfit", temp, usePreQCD = True, combineWJets = True)
temp = TFile('data/auto_copyhist/%s/central_nominal.root' % shyftMode)
dumpStitched("stitched", temp, usePreQCD=True)
temp = TFile('data/auto_copyhist/%s/central_flipiso.root' % shyftMode)
dumpStitched("flipiso", temp)
temp = TFile('data/auto_copyhist/%s/central_giantQCD.root' % shyftMode)
dumpStitched("giantQCD", temp)

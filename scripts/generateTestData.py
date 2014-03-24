#!/usr/bin/env python

# generates test data needed to closure-test the fitter

# Keep ROOT from gobbling command line arguments
import sys
from SUSHyFT.HistogramDumper import HistogramDumper
oldarg = sys.argv[:]
sys.argv = [oldarg[0], '-b']
import ROOT
sys.argv = oldarg[:]

# Parse arguments
from optparse import OptionParser
parser = OptionParser()
parser.add_option('--targetPrefix', help='Outputs to write', default='test')
opts, args = parser.parse_args()

# needed for having multiple of these
testMode = "test1"

# cheatsheat for computed values (keep in sync with stitch cfg)
# stitch scaliing is xs * globalSF*lum/n_gen
cheat = { 'lftag' : 1.01,
          'btag' : 0.93,
          'Q2' : 0.91,
          'JES' : 0.98,
          'dataLum' : 12345,
          'Top' : {'xsec' : 300,
                   'ngen' : 100},
          'Wbx' : {'xsec' : 75,
                   'ngen' : 200},
          'Wcx' : {'xsec' : 150,
                   'ngen' : 200},
          'Wqq' : {'xsec' : 225,
                   'ngen' : 200},
          'wjets' : {'ngen' : 600},
          'ZJets' : {'xsec' : 200,
                   'ngen' : 500},
          'SingleTop' : {'xsec' : 10,
                   'ngen' : 600},
          'QCD' : {'xsec' : 100,
                   'ngen' : 700} }

# throw some test distribution into the histogram
sampleList = ('Top', 'wjets', 'ZJets', 'SingleTop', 'QCD')
subSampleList = [('Wbx','_b'),
                      ('Wcx','_c'),
                      ('Wqq','_q')]

def generateHistName(sample, kinematic, jet, tag, suffix):
    return "%s_%s_%sj_%st%s" % (sample, kinematic,
                                jet, tag, suffix)


def fillHist(hist, sample, jet, tag, subSample, kinematic):
    simpleFunc = ROOT.TF1("autoFilled", "TMath::Poisson(x,[0])",0,200)
    sampleIndex = [x for x in sampleList]
    sampleIndex.extend([x[0] for x in subSampleList])
    # set the peaks of the poissons
    simpleFunc.SetParameter(0,10.0 * sampleIndex.index(sample) + jet + tag)
    # set the scaling of the poissons
    simpleFunc.SetParameter(1,1.0)
    hist.Eval(simpleFunc)
    hist.Scale(max(1, 8 - jet - tag))

# generator to collapse these loops
def forAllBinsInSample(sample):
    subSamples = [("","")]
    if sample == 'wjets':
        subSamples = subSampleList
    for subSample, suffix in subSamples:
        for jet in range(10): # zero-indexed
            for tag in range(6):
                if tag > jet:
                    continue
                for kinematic in ('secvtxMass','MET'):
                    yield (jet, tag, subSample, suffix, kinematic)
def forAllBins():
    for sample in sampleList:
        for (jet, tag, subSample, suffix, kinematic) in forAllBinsInSample(sample):
            yield (sample, jet, tag, subSample, suffix, kinematic)

allHists = {}
allFiles = {}
sampleSums = {}
dataFile = ROOT.TFile('%sMET%sUSER.root' % (opts.targetPrefix, testMode), 'recreate')
allFiles['data'] = dataFile

# first put the shapes into all the different files
for sample in sampleList:
    sampleFile = ROOT.TFile("%s%s_%s.root" % (opts.targetPrefix,
                                                sample,
                                                testMode),
                            'recreate')
    allFiles[sample] = sampleFile
    for jet, tag, subSample, suffix, kinematic in forAllBinsInSample(sample):
        histName = generateHistName(sample, kinematic,
                                    jet, tag, suffix)
        hist = ROOT.TH1F(histName, histName, 220,0,220)
        targetKey = sample
        if subSample:
            targetKey = subSample
        fillHist(hist, sample, jet, tag, subSample, kinematic)
        allHists[histName] = hist
        hist.SetDirectory(sampleFile)
        sampleSums[sample] = sampleSums.setdefault(sample, 0) + \
                             hist.Integral()

# now that we have the shapes, we need to normalize everything to ngen and 
# add it to the various data bins
for sample, jet, tag, subSample, suffix, kinematic in forAllBins():
    histName = generateHistName(sample, kinematic, jet, tag, suffix)
    allHists[histName].Scale(cheat[sample]['ngen']/sampleSums[sample])
    dataHistName = generateHistName('data', kinematic, jet, tag, '')
    if not dataHistName in allHists:
        allHists[dataHistName] = ROOT.TH1F(dataHistName,
                                           dataHistName,
                                           220, 0, 220)
        allHists[dataHistName].SetDirectory(allFiles['data'])
    allHists[dataHistName].Add(allHists[histName])

dump = HistogramDumper()
for k, v in allHists.iteritems():
    dump.addHistogram(k,v)
dump.dump()
for sampleFile in allFiles.values():
    sampleFile.Write()
    sampleFile.Close()

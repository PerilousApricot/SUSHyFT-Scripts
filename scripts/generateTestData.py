#!/usr/bin/env python

# generates test data needed to closure-test the fitter

# Keep ROOT from gobbling command line arguments
import glob
import itertools
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
parser.add_option('--inputShapes',
                  help='Steal shapes from here instead of generating fakes')
parser.add_option('--systematic', help='Which systematic to use for shapes',
                  default='nominal')

opts, args = parser.parse_args()

# needed for having multiple of these
testMode = "test1"

# cheatsheat for computed values (keep in sync with stitch cfg)
# stitch scaliing is xs * globalSF*lum/n_gen
cheat = { 'lftag' : 1.01,
          'btag' : 0.85,
          'Q2' : 0.91,
          'JES' : 0.98,
          'dataLum' : 150,
          'Top' : {'xsec' : 300,
                   'ngen' : 100},
          'Wbx' : {'xsec' : 75},
          'Wcx' : {'xsec' : 150},
          'Wqq' : {'xsec' : 225},
          'wjets' : {'ngen' : 600},
          'ZJets' : {'xsec' : 200,
                   'ngen' : 200},
          'SingleTop' : {'xsec' : 10,
                   'ngen' : 400},
          'QCD' : {'xsec' : 100,
                   'ngen' : 300} }

def getFilename(sample):
    if sample == 'SingleTop':
        return 'T_tW'
    return sample
# throw some test distribution into the histogram
fullStatisticsPrefix = "noMET"
smallStatisticsPrefix = "nominal"
sampleList = ('Top', 'wjets', 'ZJets', 'SingleTop', 'QCD')
subSampleList = [('Wbx','_b'),
                      ('Wcx','_c'),
                      ('Wqq','_q')]
sampleToFileMapping = { 'Top' : ['_TTJets_MassiveBinDECAY'],
                        'wjets' : ['_WJetsToLNu_TuneZ2Star'],
                        'ZJets' : ['_DYJetsToLL_M-50_TuneZ2Star'],
                        'SingleTop' : ['_T_s-','_Tbar_s-','_T_t-','_Tbar_t-','_T_tW-','_Tbar_tW-'],
                        'QCD' : ['_QCD_Pt_20_'] }
sampleToHistPrefixMapping = {'Top':'ttjets',
                             'wjets' : 'wjets',
                             'ZJets' : 'dyjets',
                             'SingleTop' : 'singletop',
                             'QCD' : 'qcd',
                             'data' : 'data'}
def generateHistName(sample, kinematic, jet, tag, suffix):
    return "%s_%s_%sj_%st%s" % (sampleToHistPrefixMapping[sample], kinematic,
                                jet, tag, suffix)


def fillHist(hist, sample, jet, tag, subSample, kinematic):
    simpleFunc = ROOT.TF1("autoFilled", "TMath::Poisson(x,[0])",0,200)
    sampleIndex = [x for x in sampleList]
    sampleIndex.extend([x[0] for x in subSampleList])
    testSample = subSample or sample
    # set the peaks of the poissons
    simpleFunc.SetParameter(0,20 * sampleIndex.index(testSample) + 1)
    # set the scaling of the poissons
    simpleFunc.SetParameter(1,1.0)
    hist.Eval(simpleFunc)
    hist.Scale(max(1, 8 - jet - tag + sampleIndex.index(testSample)))

def polynoidTruth(systematic, value, sample, jet, tag, subSample, kinematic):
    if sample == 'Top' or sample == 'SingleTop' or\
        (sample == 'wjets' and (subSample == 'Wbx' or
                                subSample == 'Wcx')):
        sign = 1
        scale = 2
        if subSample == 'Wbx':
            sign = -1
        if (tag % 2) == 1:
            sign = sign * -1
        if (jet % 2) == 1:
            scale = 4
        return 1 + (value - 1) * scale * sign
    else:
        return 1

# generator to collapse these loops
def forAllBinsInSample(sample):
    subSamples = [("","")]
    if sample == 'wjets':
        subSamples = subSampleList
    for subSample, suffix in subSamples:
        for jet in range(10): # zero-indexed
            if jet == 0:
                continue
            for tag in range(6):
                if tag > jet:
                    continue
                for kinematic in ('secvtxMass','MET'):
                    if kinematic == 'secvtxMass' and tag == 0:
                        continue
                    yield (jet, tag, subSample, suffix, kinematic)
def forAllBins():
    for sample in sampleList:
        for (jet, tag, subSample, suffix, kinematic) in forAllBinsInSample(sample):
            yield (sample, jet, tag, subSample, suffix, kinematic)

allHists = {}
allFiles = {}
sampleSums = {}
dataFile = ROOT.TFile('%snominal_MET%sUSER.root' % \
                        (opts.targetPrefix, testMode), 'recreate')
allFiles['data'] = dataFile
stolenInputs = {}
binParams = {'MET': (120, 0.0, 300.0), 'secvtxMass': (40, 0.0, 10.0)}
# first, either generate or extract shapes to use
def generateHistograms(systematic):
    sampleSums = {}
    for sample in sampleList:
        sampleFile = ROOT.TFile("%snominal_%s_%s.root" % (opts.targetPrefix,
                                                    getFilename(sample),
                                                    testMode),
                                'recreate')
        allFiles[sample] = sampleFile
        if opts.inputShapes:
            for prefix in sampleToFileMapping[sample]:
                if not sample in stolenInputs:
                    stolenInputs[sample] = []
                for oneFile in glob.glob(opts.inputShapes + prefix + '*'):
                    stolenInputs[sample].append(ROOT.TFile(oneFile))
        sampleFile.cd('')
        for jet, tag, subSample, suffix, kinematic in forAllBinsInSample(sample):
            histName = generateHistName(sample, kinematic,
                                        jet, tag, suffix)
            if opts.inputShapes:
                hist = None
                for oneInput in stolenInputs[sample]:
                    inputHist = oneInput.Get(histName)
                    if not hist:
                        hist = inputHist.Clone()
                    else:
                        hist.Add(inputHist)
            else:
                hist = ROOT.TH1F(histName, histName, *binParams[kinematic])
                fillHist(hist, sample, jet, tag, subSample, kinematic)
            allHists[systematic + histName] = hist
            hist.SetDirectory(sampleFile)
            sampleSums.setdefault(sample, {})
            sampleSums[sample][kinematic] = sampleSums[sample].setdefault(kinematic, 0) + \
                                            hist.Integral()
    return sampleSums
print sampleSums
print binParams
# now that we have the shapes, we need to normalize everything to ngen and 
# add it to the various data bins
samplesDumped = {}
for sample, jet, tag, subSample, suffix, kinematic in forAllBins():
    histName = generateHistName(sample, kinematic, jet, tag, suffix)
    if subSample:
        targetXsec = cheat[subSample]['xsec']
    else:
        targetXsec = cheat[sample]['xsec']
    dataHistName = generateHistName('data', kinematic, jet, tag, '')
    if not dataHistName in allHists:
        allHists[dataHistName] = ROOT.TH1F(dataHistName,
                                           dataHistName,
                                           allHists[histName].GetNbinsX(),
                                           allHists[histName].GetXaxis().GetXmin(),
                                           allHists[histName].GetXaxis().GetXmax()
                                           )
        allHists[dataHistName].SetDirectory(allFiles['data'])
    tempHist = allHists[histName].Clone()
    # First scale the MC by the proper ngen amount.
    allHists[histName].Scale(cheat[sample]['ngen']/sampleSums[sample][kinematic])
    # Then clone a new contribution to the data output
    tempHist.Scale(targetXsec/sampleSums[sample][kinematic]*cheat['dataLum'])
    # Then also scale by the systematic
    systScale = polynoidTruth('btag', cheat['btag'], sample,
                     jet, tag, subSample, kinematic)
    tempHist.Scale(systScale)
    allHists[dataHistName].Add(tempHist)
    sampleName = sample or subSample
    if not sampleName in samplesDumped:
        samplesDumped[sampleName] = True

dump = HistogramDumper()
for k, v in allHists.iteritems():
    dump.addHistogram(k,v)
dump.dump()

# now make polynoid inputs:
systTitles = ['BTag080','BTag090','BTag110','BTag120']
systValues = [      0.8,      0.9,     1.10,     1.20]
for systTitle, systValue in itertools.izip(systTitles,systValues):
    for (sample, jet, tag, subSample, suffix, kinematic) in forAllBins():
        if not "%s_%s" % (systTitle, sample) in allFiles:
            sampleName = "%s%s_%s_%s.root" % (opts.targetPrefix,
                                                systTitle,
                                                getFilename(sample),
                                                testMode)
            sampleFile = ROOT.TFile(sampleName,
                                    'recreate')
            allFiles["%s_%s" % (systTitle, sample)] = sampleFile
        else:
            sampleFile = allFiles["%s_%s" % (systTitle, sample)]
        histName = generateHistName(sample, kinematic, jet, tag, suffix)
        sf = polynoidTruth('btag', systValue, sample,
                             jet, tag, subSample, kinematic)
        clonedHist = allHists[histName].Clone()
        clonedHist.Scale(sf)
        clonedHist.SetDirectory(sampleFile)
        allHists["%s_%s" % (systTitle, histName)] = clonedHist

for sampleFile in allFiles.values():
    sampleFile.Write()
    sampleFile.Close()

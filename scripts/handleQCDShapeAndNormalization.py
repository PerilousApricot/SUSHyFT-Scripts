#!/usr/bin/env python

"""
    extract_qcd_norm_from_data.py - Given a stitched template with un-scaled
    data/QCD and with the rest normalized to their MC predictions, perform a fit
    for each jet/tag bin to extract the QCD normalization

    Slam the appropriate QCD. A real complicated way to end up with
    scaleQCD = [value from minifit] * (integral(normalQCD)/integral(looseQCD))

    Author: Andrew Melo, based on magic_fit.py from Andrew Ivanov
"""
import sys
oldarg = sys.argv[:]
sys.argv = [oldarg[0], '-b']
from ROOT import *
gROOT.Macro("~/rootlogon.C")
sys.argv = oldarg[:]
# ===============
# options
# ===============
from optparse import OptionParser
parser = OptionParser()
# New args added 9/2013
parser.add_option('--stitched-input', type='string', action='append',
        dest='stitched_input',
        default=[],
        help='Input to process "minifitQCD"')
parser.add_option('--qcd-shape', type='string', action='append',
        dest='qcd_shape',
        default=[],
        help='QCD shapes we want to output "looseQCD"')
parser.add_option('--qcd-signal', type='string', action='append',
        dest='qcd_signal',
        default=[],
        help='QCD from signal region "nominalQCD"')
parser.add_option('--lumi', metavar='D', type='float', action='store',
        default=19712,
        dest='lumi',
        help='Data Luminosity')
parser.add_option('--var', metavar='T', type='string', action='store',
        default='',
        dest='var',
        help='Variable to fit')
parser.add_option('--shapeOutputVar', metavar='T', type='string', action='store',
        default='',
        dest='shapeOutputVar',
        help='Variable to use when outputting shapes')


# unneeded
parser.add_option('--qcd-norm', type='string', action='append',
        dest='qcd_norm',
        default=[],
        help='QCD to use in mini/MET-fit')

# old
parser.add_option('--verbose',action='store_true',
        default=False,
        dest='verbose',
        help='verbose switch')				  
parser.add_option('--simple',action='store_true',
        default=False,
        dest='simple',
        help='simple_mode')	
parser.add_option('--fit',action='store_true',
        default=False,
        dest='fit',
        help='fitting_mode')
parser.add_option('--rebin', metavar='T', type='int', action='store',
        default=1,
        dest='rebin',
        help='rebin x axes to this')
parser.add_option('--minJets', metavar='D', type='int', action='store',
        default=1,
        dest='minJets',
        help='Minimum number of jets for plots')
parser.add_option('--maxJets', metavar='D', type='int', action='store',
        default=5,
        dest='maxJets',
        help='Minimum number of jets for plots')
parser.add_option('--nJets', metavar='D', type='int', action='store',
        default=-1,
        dest='nJets',
        help='Exact number of jets for plots')
parser.add_option('--minTags', metavar='D', type='int', action='store',
        default=0,
        dest='minTags',
        help='Minimum number of tags for plots')
parser.add_option('--maxTags', metavar='D', type='int', action='store',
        default=2,
        dest='maxTags',
        help='Minimum number of tags for plots')
parser.add_option('--nTags', metavar='D', type='int', action='store',
        default=-1,
        dest='nTags',
        help='Exact number of tags for plots')
parser.add_option('--pretagMinTags', type='int', action='store',
        default=0,
        dest='pretagMinTags',
        help='Minimum tags to sweep into pretagged things')
parser.add_option('--pretagMaxTags', type='int', action='store',
        default=2,
        dest='pretagMaxTags',
        help='Maximum tags to sweep into pretagged things')


parser.add_option('--templateDir', metavar='MTD', type='string',
        default='pfShyftAnaNoMET',
        dest='templateDir',
        help='Directory from which to get high statistics templates')

parser.add_option('--qcdDir', metavar='MTD', type='string',
        default='pfShyftAnaQCDWP95NoMET',
        dest='qcdDir',
        help='Directory from which to get qcd MC statistics')

parser.add_option('--subDir', metavar='MTD', type='string',
        default='eleEB',
        dest='subDir',
        help='Directory from which to get EE or EB statistics')

parser.add_option('--outputDir', metavar='MTD', type='string',
        default='plots_772_leg',
        dest='outputDir',
        help='Directory to store output histos')

parser.add_option('--pretagDir', metavar='MTD', type='string',
        default='plots_pre',
        dest='pretagDir',
        help='Directory to store output pretag or some combination of histos')

parser.add_option('--nBin', metavar='D', type='int', action='store',
        default=300,
        dest='nBin',
        help='Number of x-axis bin to display')

(options,args) = parser.parse_args()

# =====================================================
# class that contains all relevant plot quantities		
# =====================================================
class TDistribution:
    def __init__(self, name, var, filenames, hists):
        self.name = name
        self.legentry = "legentry"
        self.file = TFile(filenames[0])
        self.var = var
        keys = sorted(hists.keys())
                    #print keys
        print "opening %s with key %s" % (filenames[0], keys[0])
        self.hist = None
        for ihist in keys:
            if not self.hist:
                self.hist = self.file.Get(ihist)
                if not self.hist:
                    raise RuntimeError, "Histogram (%s) not found" % ihist
                continue
            histo = self.file.Get(ihist)
            try:	
                self.hist.Add(histo,hists[ihist])
                print "  Added %s to %s" % (ihist, keys[0])
            except (TypeError, AttributeError):
                if options.verbose :
                    print "No histogram ", ihist, "in file", filenames[0], " ... skipping"

                continue					
        for filename in filenames[1:] :
            file = TFile(filename)
            keys = sorted(hists.keys())
            for ihist in keys :
                histo = file.Get(ihist)
                try:
                    self.hist.Add(histo,hists[ihist])
                except TypeError:
                    if options.verbose :
                        print "No histogram ", ihist, "in file", filename, " ... skipping"
                    continue
        if options.rebin > 1 :
            self.hist.Rebin(options.rebin)
        self.integerNorm = self.hist.Integral()
        # RooFit quantities:
        self.setRooVariables()

    def setRooVariables(self):
        self.SF = RooRealVar(self.name+"SF",self.name+"SF",1.,0.,10000.)
        self.norm = RooRealVar(self.name+"Norm",self.name+"Norm",self.hist.Integral())
        self.N = RooFormulaVar(self.name+"N",self.name+"SF*"+self.name+"Norm",RooArgList(self.norm,self.SF))
        if self.var != 0 :				
            self.set = RooDataHist(self.name+"Set",self.name+"Set",RooArgList(self.var),self.hist)
            self.pdf = RooHistPdf(self.name+"Pdf",self.name+"Pdf",RooArgSet(self.var), self.set)

    def scale(self, value):
        self.hist.Scale(float(value))
        self.setRooVariables()

if options.verbose :
    print "script to create normalized plots"
dirMain     = "../RootFiles_v5/"
tempDir     = options.templateDir
qcdDir      = options.qcdDir
subDir      = options.subDir
reg         = subDir[-8:]

nJet = '{0:1.0f}'.format( options.nJets)
nTag = '{0:1.0f}'.format( options.nTags)
minJ = '{0:1.0f}'.format( options.minJets)
maxJ = '{0:1.0f}'.format( options.maxJets)
minT = '{0:1.0f}'.format( options.minTags)
maxT = '{0:1.0f}'.format( options.maxTags)
lum  = '{0:1.0f}'.format( options.lumi)

if options.var == "secvtxMass" :
    xtitle = "Secondary Vertex Mass (GeV), #geq 3j #geq 1t"
elif options.var == "MET" :
    xtitle = "Missing Transverse Energy (GeV), #geq 3j #geq 1t"
elif options.var == "wMT" :
    xtitle = "W Transverse Mass (GeV), #geq 3j #geq 1t"
elif options.var == "hT" :
    xtitle = "hT, #sum (Jet et + MET + lep pt) (GeV), #geq 3j #geq 1t"
elif options.var == "lepPt" :
    xtitle = "electron pt, #geq 3j #geq 1t"
elif options.var == "lepEta" :
    xtitle = "electron #eta, #geq 3j #geq 1t"
elif options.var == "jetEt" :
    xtitle = "electron jet Et, #geq 3j #geq 1t"
else :
    xtitle =""


if options.nJets >= 0:
    options.minJets = options.nJets
    options.maxJets = options.nJets
    minJ            = nJet
    maxJ            = nJet
if options.nTags >= 0 :
    options.minTags = options.nTags
    options.maxTags = options.nTags
    minT            = nTag
    maxT            = nTag

# add different jets/tags histograms
# it also mutates the dict which is some kind of maddening bullshit
def getHistogramNames(hists,doPretagged=False):
    retval = {}
    keys = sorted(hists.keys())
    if options.verbose:
        print "Keys: ", keys
        print hists
    myMinTags = options.minTags
    myMaxTags = options.maxTags
    if doPretagged:
        myMinTags = options.pretagMinTags
        myMaxTags = options.pretagMaxTags
    for ikey in keys[:]:
        weight = hists[ikey]
        ikey_tmp = ikey + "_" + options.var
        #print ikey_tmp
        bins = {}
        myMinTags = options.minTags
        for nJets in range(options.minJets, options.maxJets+1):
            for nTags in range(myMinTags, myMaxTags+1):
                temp_key = "_" + str(nJets) + "j_" + str(nTags) + "t"
                bins[temp_key] = weight
        bin_keys = sorted(bins.keys())
        for ibin in bin_keys[:]:
            ikey_new = ikey_tmp + ibin
            retval[ikey_new] = bins[ibin]
    if True:#options.verbose :	
        for ikey in hists.iteritems():
            print "In add %s" % [ikey]
    return retval

def init_var(dist) :
    NBINS = dist.hist.GetNbinsX()
    minX = (dist.hist.GetXaxis()).GetXmin()
    maxX = (dist.hist.GetXaxis()).GetXmax()
    var = RooRealVar(options.var,xtitle,minX,maxX)
    var.setBins(NBINS)
    dist.set = RooDataHist(dist.name+"Set",dist.name+"Set",RooArgList(var),dist.hist)
    return var

#_____________________________data_________________________________
hists = {'Data' : 1}
histNames = getHistogramNames(hists)
data = TDistribution("data", 0, filenames = options.stitched_input,hists = histNames)
data.legentry = "Data("+lum+"pb^{-1})"
data.hist.SetMarkerStyle(8)
data.error = "e"
templates = [data]

var = init_var(data)
#___________________________EWK (single-top + WJets)____________________________
hists = {'SingleTop' : 1, 'Wbx' : 1, 'Wcx' : 1, 'Wqq' : 1}
histNames = getHistogramNames(hists)
ewk = TDistribution("ewk",var, filenames = options.stitched_input,hists = histNames)
ewk.scale(lum)
ewk.legentry = "EWK/TOP"
ewk.hist.SetFillColor(4)
templates.append(ewk)

#_________________________________ZJets_________________________________________
hists = {'ZJets' : 1 }
histNames = getHistogramNames(hists)
dy = TDistribution("dy", var, filenames = options.stitched_input,hists = histNames)
dy.scale(lum)
dy.legentry = "Z+jets"
dy.hist.SetFillColor(2)
templates.append(dy)

#________________________________TTBar_________________________________________
hists = {'Top' : 1 }
print hists
histNames = getHistogramNames(hists)
print histNames
top = TDistribution("top", var, filenames = options.stitched_input,hists = histNames)
top.scale(lum)
top.legentry = "t #bar{t}"
top.hist.SetFillColor(206)
templates.append(top)

#____________________________qcd______________________________________
hists = {'QCD' : 1}
histNames = getHistogramNames(hists,doPretagged=True)
histNamesTagged = getHistogramNames(hists)

# Handle the QCD. First, get the input
if not options.qcd_signal:
    options.qcd_signal = options.stitched_input
if not options.qcd_shape:
    options.qcd_shape = options.stitched_input
if not options.qcd_norm:
    options.qcd_norm = options.stitched_input
qcd = TDistribution("qcd", var, filenames = options.qcd_norm,hists = histNames)
qcd_signal = TDistribution("qcd", var, filenames = options.qcd_signal,hists = histNamesTagged)
qcd_shape  = TDistribution("qcd", var, filenames = options.qcd_shape,hists = histNamesTagged)
if True:
    # do I want to scale here?
    qcd.scale(lum)
    qcd_signal.scale(lum)
    qcd_shape.scale(lum)

qcd.legentry = "QCD"
qcd.hist.SetFillColor(6)
templates.append(qcd)


# scaleQCD = [value from minifit]*(integral(normalQCD)/integral(looseQCD)) *
#           DROP THIS THOUGH (I think)(integral(normalQCD)/integral(miniFitQCD))
# since we're just passing value from minifit back up to the main fit,
# add the next two terms in as well
# do it by first scaling QCD by the reciprocal of the previous two values
#   Variables:
#     qcd: minifit
#     qcd_shape: looseQCD
#     qcd_signal: nominal`
sum_pdf = RooAddPdf("SumPdf","SumPdf",RooArgList(qcd.pdf,ewk.pdf,dy.pdf,top.pdf),RooArgList(qcd.N,ewk.N,dy.N,top.N))
#ewk_constr = RooGaussian("ewk_constr","ewk_constr",ewk.SF,RooFit.RooConst(1.),RooFit.RooConst(0.05))
zjet_constr = RooGaussian("zjet_constr","zjet_constr",dy.SF,RooFit.RooConst(1.),RooFit.RooConst(0.10))
#all_constraints = [ zjet_constr.SF ]
#tot_pdf = RooProdPdf("TotPdf","TotPdf",RooArgList(sum_pdf,ewk_constr))#,zjet_constr))
tot_pdf = RooProdPdf("TotPdf","TotPdf",RooArgList(sum_pdf,zjet_constr))
##sum_pdf = RooAddPdf("SumPdf","SumPdf",RooArgList(qcd.pdf,ewk.pdf,wjets.pdf),RooArgList(qcd.N,ewk.N,wjets.N))
##	ewk_constr = RooGaussian("ewk_constr","ewk_constr",ewk.SF,RooFit.RooConst(1.),RooFit.RooConst(0.05))
##	tot_pdf = RooProdPdf("TotPdf","TotPdf",RooArgList(sum_pdf,ewk_constr))

#args = [ data.set ]
#args.extend(all_constraints)
#args.extend([RooFit.Extended(kTRUE),RooFit.Range("fix"),RooFit.Save()])
#print "got args %s" % args
#r = tot_pdf.fitTo(*args)
r = tot_pdf.fitTo(data.set,RooFit.Constrain(RooArgSet(dy.SF,ewk.SF)),RooFit.Extended(kTRUE),RooFit.Range("fix"),RooFit.Save())
params = tot_pdf.getVariables()
print "params are %s" % params
params.Print("v")


for idist in templates[1:]:
    print idist.hist.Print()
    print "This is the scale %s" % params.find(idist.name+"SF").getVal()
    idist.hist.Scale(params.find(idist.name+"SF").getVal())

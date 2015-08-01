#! /usr/bin/env python

import ROOT
import optparse
import sys
import re
import pprint
import os
import math
import time
from FitterConfig import FitterConfig

tildeRE = re.compile (r'(\S+)~(\S+)')
underRE = re.compile (r'_')
colonRE = re.compile (r'(\S+):(\S+)')

def parseAxisLabels (input):
    pieces = underRE.split (input)
    retval = []
    for piece in pieces:
        match = colonRE.search (piece)
        if not match:
            raise RuntimeError, "Do not understand axis label piece '%s'" \
                  % piece
        try:
            retval.append( ( int (match.group(1)), match.group(2) ) )
        except:
            raise RuntimeError, "Do not understand axis label piece '%s'" \
                  % piece
    return retval

##   double sumchi = 0.0, diff = 0.0, add = 0.0, data = 0.0, prediction = 0.0;
##     
##   for (int i = 1; i <= parent->GetNbinsX(); i++) {
##     data = parent->GetBinContent(i);
##     prediction = test->GetBinContent(i);
##     if (prediction != 0) {
##       if (data != 0) {
##         sumchi += 2 * (prediction - data + (data * TMath::Log(data / prediction)));
##       } else {
##         sumchi += 2 * (prediction - data);
##       }
##     }
##   }

def bakerCousinsChiSquared (dataHist, fitHist):
    '''Given a data and fit histogram, calculate the Baker-Cousins
    chi^2'''
    numBins = dataHist.GetNbinsX()
    sumChi2 = 0.
    for bin in range (1, numBins + 1): # 1..numBins
        data = dataHist.GetBinContent (bin)
        fit  = fitHist.GetBinContent (bin)
        if not fit and data:
            print "Warning: bin %d has no prediction, but has data (%d)." \
                  % (bin, data)
            continue
        if data:
            sumChi2 += 2 * (fit - data + (data * math.log (data / fit) ) )
        else:
            sumChi2 += 2 * (fit - data)
    return sumChi2

if __name__ == "__main__":
    # Setup options parser
    parser = optparse.OptionParser \
             ("usage: %prog [options] config.txt templates.root [output.png]" \
              "Prints out info on templates.")
    parser.add_option ("--groups", dest='groups', action="append",
                       type="string", default=[],
                       help="Which groups to use for plot")
    parser.add_option ('--combineGroups', dest = 'combineGroups',
                       action='append', type='string', default=[],
                       help='Groups to combine');
    parser.add_option ('--combineSamples', dest = 'combineSamples',
                       action='append', type='string', default=[],
                       help='Samples to combine');
    parser.add_option ('--axisLabels', dest = 'axisLabels',
                       action='append', type='string', default=[],
                       help='Axis labels to use ("_1j_1t~1:0_10:5")');
    parser.add_option ('--units', dest='units', type='string',
                       help='Unit label of axis', default='')
    parser.add_option ('--yaxis', dest='yaxistitle', type='string',
                       help='y-axis label', default='')
    parser.add_option ("--latex", dest='latex',
                       action='store_true',
                       help="Formats output as latex table")
    parser.add_option ('--chi2', dest='chi2', action='store_true',
                       default=False,
                       help='Calculate chi2')
    parser.add_option ('--showCounts', dest='showCounts', action='store_true',
                       default=False,
                       help='Show counts')
    parser.add_option ('--debug', dest='debug', action='store_true',
                       default=False,
                       help='debug')
    parser.add_option ('--title', dest='title', type='string',
                       default='',
                       help='Plot Title')
    parser.add_option ('--relTextSize', dest='relativeTextSize', type='float',
                       default=1.0,
                       help='Relative text size (default %default)')
    parser.add_option ('--text', dest='text', type='string',
                       help='Place text where title would be')
    parser.add_option ('--logY', dest='logY', action='store_true',
                       default=False,
                       help='set y-axis to log scale')


    options, args = parser.parse_args()
    ROOT.gROOT.SetBatch()
    ROOT.gROOT.SetStyle('Plain')
    ROOT.gStyle.SetOptStat (0)
    ROOT.gStyle.SetTitleFont(42, 'XYZ')
    ROOT.gStyle.SetTitleSize(0.05, 'XYZ')
    ROOT.gStyle.SetLabelFont(42, "XYZ");
    ROOT.gStyle.SetLabelOffset(0.007, "XYZ");
    ROOT.gStyle.SetLabelSize(0.05, "XYZ");
    ROOT.gStyle.SetPadTopMargin(0.1);
    ROOT.gStyle.SetPadBottomMargin(0.13);
    ROOT.gStyle.SetPadLeftMargin(0.16);
    ROOT.gStyle.SetPadRightMargin(0.02);
              
    if len (args) < 2:
        print "Need to provide configuration and template files. Aborting."
        sys.exit(1)
    configName = args[0]
    config = FitterConfig (configName)

    if options.debug:
        print "%s" % config

    allLabels = []
    for chunk in options.axisLabels:
        allLabels.extend( FitterConfig.commaRE.split (chunk) )
    generalAxis = []
    axisDict = {}
    for label in allLabels:
        match = tildeRE.search (label)
        if match:
            name = match.group(1)
            
            axisDict.setdefault (name, []).\
                                extend( parseAxisLabels( match.group(2) ) )
        else:
            generalAxis.extend( parseAxisLabels (label) )

    if options.chi2:
        config.loadHistogramsFromFitterOutput (args[1])
        data = config.fitterHists['Data']
        fit  = data.Clone('Fit')
        fit.Reset()
        for name in config.fitterHists.keys():
            if name == 'Data':
                continue
            fit.Add( config.fitterHists[name] )
        print "chi2", bakerCousinsChiSquared (data, fit), \
              "bins", data.GetNbinsX()
        sys.exit()

    #######################
    ## Print out counts? ##
    #######################
    if options.showCounts:
        config.printMCtotal = True
        config.latex        = options.latex
        config.setCombineGroups  (options.combineGroups)
        config.setCombineSamples (options.combineSamples)
        config.getNormsFromFitterOutput (args[1])
        config.printInfo (alreadyLoaded=True)
        sys.exit()


    ###################
    ## Shrink plots! ##
    ###################
    # Assemble complete list of groups and make sure each group listed
    # is a real group    
    groups = []
    for group in options.groups:
        groups.extend( FitterConfig.commaRE.split (group) )
    for group in groups:
        if group not in config.groupNames:
            raise RuntimeError, "Group '%s' is not in %s." \
                  % (group, config.groupNames)
    # Make sure we have the right number of arguments
    if len (args) < 3:
        raise RuntimeError, "Need to provide configuration and template files as well as output filename"
    pieces = os.path.splitext(args[2])
    output = "%s%s%s" % (pieces[0], "".join(groups), pieces[1])
    # calculate how many bins we need
    numTotalBins = 0
    boundaries = []
    labels = []
    for group in groups:
        oldEdge = numTotalBins
        numTotalBins += config.groupBins[group][0]
#        labels.append( ( (oldEdge + numTotalBins) / 2.,
#                         config.groupStrings[group]) )
        labels.append( ( 0.25*oldEdge + numTotalBins*0.75,
                         config.groupStrings[group]) )
        boundaries.append (numTotalBins)        
    # load histograms
    config.loadHistogramsFromFitterOutput (args[1])
    newHistDict = {}
    binNames = []
    for name in config.sampleNames:
        isData = name == 'Data'
        oldHist = config.fitterHists[name]
        hist = newHistDict[name] = ROOT.TH1F (name, name, numTotalBins, 0, numTotalBins)
        hist.SetMarkerStyle ( oldHist.GetMarkerStyle() )
        hist.SetLineColor   ( oldHist.GetLineColor()   )
        hist.SetLineWidth   ( oldHist.GetLineWidth()   )
        hist.SetFillColor   ( oldHist.GetFillColor()   )
        axis = hist.GetXaxis()
        #if isData:
        #   axis.SetTitle (options.units)
        axis.SetTitle (options.units)
        yaxis = hist.GetYaxis()
        yaxis.SetTitleOffset(1.33)
        yaxis.CenterTitle(1)
        yaxis.SetTitle(options.yaxistitle)
        oldMax = 1
        for group in groups:
            axislabels = axisDict.get (group, generalAxis)
            for tup in axislabels:
                value = oldMax - 1 + tup[0]
                if isData:
                    axis.SetBinLabel (value, tup[1])
                    binNames.append( (value, tup[1]) )
#                else:
#                    axis.SetBinLabel (value, '')
            binTup = config.groupBins[group]
            numBins  = binTup[0]
            firstBin = binTup[1]
            for bin in range (numBins):
                oldCont = oldHist.GetBinContent( bin + firstBin )
                hist.SetBinContent( bin + oldMax, oldCont )
                if isData:
                    hist.SetBinError( bin + oldMax, math.sqrt (oldCont) )
            oldMax += numBins
    ROOT.gStyle.SetOptStat(0)
    c1 = ROOT.TCanvas()
    stack = ROOT.THStack ("SomeName", options.title)
    reverseSamples = config.sampleNames[:]
    reverseSamples.reverse()
    stackMax = 0
    dataHist = None
    # loop over verythingg backards
    for name in reversed( config.sampleNames ):
        if name == 'Data':
            dataHist = newHistDict[name]
            break
        stack.Add( newHistDict[name] )
    if options.logY:
        stackMax = math.pow(max (stack.GetMaximum(), dataHist.GetMaximum()),1.1)
    else:
        stackMax = 1.1 * max (stack.GetMaximum(), dataHist.GetMaximum())
    stack.SetMaximum (stackMax)
    #stackMax = stack.GetMaximum()
    # note you have to draw the stack before axis exists
    stack.Draw()    
    axis = stack.GetXaxis()
    for tup in binNames:
        axis.SetBinLabel (tup[0], tup[1])
    axis.SetTitle(options.units)
    yaxis = stack.GetYaxis()
    yaxis.SetTitle(options.yaxistitle)
    yaxis.SetTitleOffset(1.33)
    yaxis.CenterTitle(1)
    stack.Draw()
#    dataHist.Draw('P same')
    dataHist.SetMarkerSize(0.9)
    dataHist.SetMarkerStyle(20)
    dataHist.Draw('PE same')
    #dataHist.RedrawAxis()
    # Draw some lines
    line = ROOT.TLine()
    #line.SetWidth(1)
    text = ROOT.TText()
    text.SetTextAlign (12)
    text.SetTextAngle (90)
    text.SetTextFont(42)
    text.SetTextSize (0.05)
    if len (labels) > 1:
        for tup in labels:
            if options.logY:
                text.DrawText(tup[0]+0.5, math.pow(stackMax,0.7), tup[1])
            else:
                text.DrawText (tup[0], 0.6 * stackMax, tup[1])
    for edge in boundaries:
        line.DrawLine (edge, 0, edge, stackMax)
    if options.text:
        latex = ROOT.TLatex()
        latex.SetTextSize (0.05)
        latex.SetTextFont (42)
#        latex.DrawLatex (0.05 * edge, 1.07 * stackMax, options.text)
        if options.logY:
            latex.DrawLatex (0, math.pow(stackMax,1.07), options.text)
        else:
            latex.DrawLatex (0, 1.07 * stackMax, options.text)
        latex.SetTextAlign(22)
    c1.Draw()
    if options.logY :
        c1.SetLogy()
    c1.Print (output)

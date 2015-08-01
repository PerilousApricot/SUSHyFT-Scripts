#!/usr/bin/python

from SHyFT.ROOTWrap import ROOT

class StackedPlot:
    """
        Wrapper around functions to make a stacked SHyFT-style plot
        of kinematic distributions
    """
    def __init__(self):
        self.shapes = []
        self.title = ''
        self.xAxisTitle = ''

    def isData(self, shapeInfo):
        return shapeInfo['name'].lower().startswith('data')

    def addQuantity(self, name, shape, color = None):
        """
            Add a kinematic quantity to the stacked plot
        """
        self.shapes.append({'name':name, 'shape':shape})
        if color != None:
            self.shapes[-1]['color'] = color

    def getFilteredShapes(self, dropPattern):
        for shape in self.shapes:
            if dropPattern and dropPattern not in shape['name']:
                yield shape
            elif not dropPattern:
                yield shape

    def draw(self, filename, nostack=False, dropPattern=""):
        """
            Draw the current image
        """
        if not nostack:
            drawOpt = "HIST"
        else:
            drawOpt = "nostack,HIST"
        myCanvas = ROOT.TCanvas("c1","stacked hists",10,10,900,700);
        oldPad = ROOT.gPad
        myCanvas.cd()
        hs = ROOT.THStack('hs',self.title)
        r = 0
        if nostack:
            for shape in self.getFilteredShapes(dropPattern):
                integral = shape['shape'].Integral()
                shape['oldshape'] = shape['shape']
                shape['shape'] = shape['shape'].Clone()
                if integral:
                    shape['shape'].Scale(1/integral)
        for shape in self.getFilteredShapes(dropPattern):
            shape['shape'].SetOption('')
            if self.isData(shape):
                continue
            # 2 is red. Go figure.
            if 'color' in shape:
                if nostack:
                    shape['shape'].SetLineColor(shape['color'])
                    shape['shape'].SetFillColor(ROOT.kWhite)
                    shape['shape'].SetLineWidth(4)
                else:
                    shape['shape'].SetLineColor(ROOT.kBlack)
                    shape['shape'].SetFillColor(shape['color'])
                    #shape['shape'].SetLineWidth(1.0)
            else:
                shape['shape'].SetFillColor(2+r)
                if nostack:
                    shape['shape'].SetLineColor(2+r)
                else:
                    shape['shape'].SetLineColor(ROOT.kBlack)
                r += 1
            hs.Add(shape['shape'])
        #if not nostack:
        #    hs.Draw(drawOpt)
        #else:
        #    first = True
        #    for shape in self.shapes:
        #        if first:
        #            shape['shape'].Draw()
        #        else:
        #            shape['shape'].Draw('same')
        hs.SetDrawOption(drawOpt)
        hs.Draw(drawOpt)
        hs.SetDrawOption(drawOpt)
        for shape in  self.getFilteredShapes(dropPattern): 
            if self.isData(shape):
                if shape['shape'].GetMaximum() > hs.GetMaximum():
                    hs.SetMaximum(shape['shape'].GetMaximum())
                    pass
                if not nostack:
                    shape['shape'].Draw('esame')
                else:
                    shape['shape'].Draw('HIST,same')
        if self.xAxisTitle:
            axis = hs.GetXaxis()
            axis.SetTitle(self.xAxisTitle)
        myCanvas.RedrawAxis()
        leg = ROOT.TLegend(0.65,0.7,0.99,0.99)
        #leg = ROOT.TLegend()
        for shape in reversed([x for x in self.getFilteredShapes(dropPattern)]):
            if self.isData(shape):
                #shape['shape'].SetLineColor(ROOT.kBlack)
                if not nostack:
                    leg.AddEntry(shape['shape'],shape['name'],"pl")
                else:
                    leg.AddEntry(shape['shape'],shape['name'],"l")
        for shape in reversed([x for x in self.getFilteredShapes(dropPattern)]):
            if not self.isData(shape):
                #shape['shape'].SetLineColor(ROOT.kBlack)
                if not nostack:
                    leg.AddEntry(shape['shape'],shape['name'],'f')
                else:
                    leg.AddEntry(shape['shape'],shape['name'],'l')
        leg.Draw()
        myCanvas.SaveAs(filename)
        myCanvas.Close()
        ROOT.gPad = oldPad
        if nostack:
            for shape in self.getFilteredShapes(dropPattern):
                shape['shape'] = shape['oldshape']


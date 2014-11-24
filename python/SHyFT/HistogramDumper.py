"""
    Class to dump histogram normalizations to the console"""

import re

def customSorted(x,y):
    if x == 'data':
        return -1
    elif y == 'data':
        return 1
    else:
        return x<y

class HistogramDumper:
    def __init__(self):
        self.inputHistograms = {}
        self.sheetBuffer = [{}]
        self.sheetIndex  = 0
        self.maxColumnLength = [{}]
    def addHistogram(self, name, hist):
        self.inputHistograms[name] = hist
    def decomposeHistName(self, x):
        pattern = r"^(.*)_(.*)_(.*)j_(.*)t(.*)$"
        matchObj = re.match(pattern, x)
        if not matchObj:
            raise RuntimeError, "Couldn't match re expression"
        # this should be put somewhere else, I feel
        return matchObj.group(1,2,3,4,5)
    
    def makeBinName(self, jet, tag):
        return "%sj_%st" % (jet, tag)

    def setCellValue(self, x, y, value):
        sheet = self.sheetBuffer[self.sheetIndex]
        sheet.setdefault(y, {})
        sheet[y][x] = value
        self.maxColumnLength[self.sheetIndex].setdefault(x,0)
        self.maxColumnLength[self.sheetIndex][x] = max(
                                self.maxColumnLength[self.sheetIndex][x],
                                len(value))

    def dump(self):
        samples = []
        kinematics = []
        jets = []
        tags = []
        suffixes = []
        sampleTitles = []
        binNames = []
        addingThings = ( (samples, 'sample'),
                         (kinematics, 'kinematic'),
                         (jets, 'jet'),
                         (tags, 'tag'),
                         (suffixes, 'suffix'),
                       )
        for k in self.inputHistograms:
            sample, kinematic, jet, tag, suffix = self.decomposeHistName(k)
            for oneThing in addingThings:
                if not locals()[oneThing[1]] in oneThing[0]:
                    oneThing[0].append(locals()[oneThing[1]])
            if not "%s%s" % (sample, suffix) in sampleTitles:
                sampleTitles.append("%s%s" % (sample, suffix))
            if not self.makeBinName(jet, tag) in binNames:
                binNames.append(self.makeBinName(jet, tag))

        columnNames = sorted(sampleTitles, cmp=customSorted)
        binNames.sort()
        idx = 1
        for k in columnNames:
            self.setCellValue(idx,0,k)
            idx += 1
        idx = 1
        for k in binNames:
            self.setCellValue(0,idx,k)
            idx += 1
        for k in self.inputHistograms:
            sample, kinematic, jet, tag, suffix = self.decomposeHistName(k)
            binName = self.makeBinName(jet, tag)
            self.setCellValue(columnNames.index("%s%s" % (sample, suffix)) + 1,
                              binNames.index(binName) + 1,
                              "%.2f" % self.inputHistograms[k].Integral())
        self.printTable()
    
    def printTable(self):
        for sheetIdx in range(len(self.sheetBuffer)):
            sheet = self.sheetBuffer[sheetIdx]
            for row in range(max(sheet.keys()) + 1):
                rowBuffer = []
                if not row in sheet:
                    print ""
                    continue
                for col in range(max(sheet[row].keys()) + 1):
                    value = sheet[row].get(col, "")
                    # pad and right justify
                    padding = self.maxColumnLength[sheetIdx].get(col, 0) - len(value)
                    rowBuffer.append(' '*padding + value)
                print " | ".join(rowBuffer)

    def findHistByName(self, sample, kinematic, jet, tag, suffix):
        for k in self.inputHistograms:
            if (sample, kinematic, jet, tag, suffix) == self.decomposeHistName(k):
                return self.inputHistograms[k]
        raise RuntimeError, "Couldn't find given histogram"

    def addRow(self, row):
        self.rowBuffer.append(row)

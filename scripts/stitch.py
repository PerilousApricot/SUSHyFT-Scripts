#!/usr/bin/env python

# template of stitching script for new (and also old) SHyFT workflow
#
# usage: python stich.py input_dir output_dir yourConfigFile1.cfg [yourConfigFile2.cfg] ...
#
# Applies each config in order to allow overriding variables
# Adding the option --getInputFiles dumps thelist of input files to stdout, but doesn't run the actual
# stitching

import ConfigParser, re, sys

from SHyFT.ROOTWrap import ROOT

inputFileMode = False
if '--getInputFiles' in sys.argv:
    sys.argv.remove('--getInputFiles')
    inputFileMode = True
input_dir = sys.argv[1]
output_dir = sys.argv[2]
config = ConfigParser.ConfigParser()
config.read(sys.argv[3])
config.set('DEFAULT', 'input_folder', input_dir)
config.set('DEFAULT', 'output_folder', output_dir)
if len(sys.argv) > 4:
    config.read(sys.argv[4:])

if inputFileMode:
    inputFiles = []
    outputFiles = []
    for section in config.sections():
        toOpen = config.get(section,'input_folder')+'/'+config.get(section,'input_file')
        inputFiles.append(toOpen)

        # open a subfolder in the root file if needed
        root_dir=''
        if config.has_option(section,'root_dir'):
            root_dir = config.get(section,'root_dir')

        suffix=''
        if config.has_option(section,'suffix'):
            suffix = config.get(section,'suffix')

        prefix=section
        if config.has_option(section,'prefix'):
            prefix = config.get(section,'prefix')

        # add this to the output file names (like pfShyftAna in old format)
        outfile_suffix=''
        if config.has_option(section,'outfile_suffix'):
            outfile_suffix = config.get(section,'outfile_suffix')
        
        outfile_prefix='stitched_'
        if config.has_option(section, 'outfile_prefix'):
            outfile_prefix = config.get(section, 'outfile_prefix')

        outfname = config.get(section,'output_folder') + '/' + outfile_prefix + root_dir + outfile_suffix + '.root'
        outputFiles.append(outfname)
    print outputFiles[0]
    print "\n".join(inputFiles)
    sys.exit(0)

# ----------------------
# function definitions
# ----------------------

# returns list of histograms in the file (root directory)
# and list of folders (to deal with EB_plus, EB_minus, etc.)
def listDirsNames(tfile, rootdir):
    dirs=[]
    th1s=[]
    if rootdir!='':
        tdir = tfile.Get(rootdir)
        if tdir.IsZombie():
            #print 'no such filder in the root file: ', rootdir
            return dirs,th1s
        keylist = tdir.GetListOfKeys()
    else:
        keylist = tfile.GetListOfKeys()

    for key in keylist:
        if key.GetClassName()=='TH1F':
            th1s.append(key.GetName())
        elif key.GetClassName()=='TDirectoryFile':
            dirs.append(key.GetName())

    return dirs,th1s

# returns list of names to consider in stitching
def selectDirNames(names, hist_to_read, suffix):
    filtered = []
    if suffix:
        valid = re.compile(hist_to_read+suffix+'$')
    else:
        valid = re.compile(hist_to_read)
    for n in names:
        if valid.search(n):
            filtered.append(n)
    return filtered

def getHist(tfile, root_dir, name):
    readname=''
    if root_dir!='':
        readname = root_dir + '/'

    readname += name
    #print 'getting ',readname
    th1 = tfile.Get(readname)
    if th1.IsZombie():
        print 'no such histogram!'
        return None
    return th1

# get a clone of the histogram, considering its location
def getClone(tfile, root_dir, name):
    th1 = getHist(tfile, root_dir, name)
    cloned = th1.Clone()
    cloned.Sumw2()
    return cloned

# substitute the leading part of the name (Top, WJets, etc) by user-defined prefix
# will help to deal with multiple single top templates, for example
def recombineName(name,prefix,suffix):
    out = '_'
    l = name.split('_')
    l.insert(0,prefix)
    if l[-1] in ('b','c','q'):
        l.pop()
    retval = out.join(l)
    #print "popping %s, %s, %s to %s" % (name, prefix, suffix, retval)
    return retval

# scale histogram using all information provided in the config
# sections that have 'Data' or 'QCD' in their names have special treatment - they are not rescaled
# in case of QCD it is needed to deal with externally produced templates
histogramList = {}
def getScaleHistogram(hclone, nEvents, config, section):
    sf=1.0
    global histogramList
    if 'Data' in section or \
            ('QCD' in section and \
                (config.has_option(section, 'force_scale_qcd') and \
                 config.get(section, 'force_scale_qcd'))):
    #if 'Data' in section:
        # special treatment for data (do nothing)
        histogramList[section] = {'xs':'n/a', 'globalSF':'n/a', 'lum':'n/a', 'n_gen':'n/a', 'scale':1}
        pass
    else:
        xs = eval(config.get(section, 'xs'))
        #xs = config.getfloat(section, 'xs')
        #print 'xs ', xs
        globalSF = config.getfloat(section, 'globalSF')
        lum = config.getfloat(section, 'lum')
        if config.has_option(section, 'n_gen'):
            n_gen = config.getfloat(section, 'n_gen')
        else:
            n_gen = nEvents
        #print 'SF ',globalSF, ',lum ', lum, ',n_gen' , n_gen
        sf*=xs*globalSF*lum/n_gen
        #print "Scale factor for %s is %s" % (section, sf)
        #print " xs %s global sf %s lum %s n_gen %s" % (xs, globalSF, lum, n_gen)
        histogramList[section] = {'xs':xs, 'globalSF': globalSF, 'lum': lum, 'n_gen': n_gen, 'scale':sf}
    return sf

# extract template histogram if needed. normalize it to 1.0
def getTemplate(infile, config, section):
    # so far we need only one template per sample, we do not differentiate plus/minus etc.
    if config.has_option(section,'template_hist'):
        if config.has_option(section,'template_file'):
            # we have to open some external file
            extrafile = ROOT.TFile(config.get(section,'input_folder')+'/'+
                                   config.get(section,'template_file'),'READONLY')
            if extrafile.IsZombie():
                raise RuntimeError, 'No file %s in %s' % \
                                        (config.get(section,'template_file'),
                                            config.get(section,'input_folder'))
            template = getClone(extrafile, '', '', config.get(section,'template_hist'))
            template.SetDirectory(infile.GetDirectory(''))
            extrafile.Close()
        else:
             # read the template from input_file
             template = getClone(infile, '', '', config.get(section,'template_hist'))
        template.Scale(1.0/template.Integral())
        return template
    else:
        return None


# ------------
# main part
# ------------
inputFiles = {}
outputFiles = {}

# loop over sections (samples)
for section in sorted(config.sections()):
    print '========================='
    print 'Section: ',section
    print '========================='
    print config.items(section)
    toOpen = config.get(section,'input_folder')+'/'+config.get(section,'input_file')
    infile = ROOT.TFile(toOpen,'READONLY')

    eventHist = infile.Get('nEvents')
    nEvents = eventHist.GetEntries()
    if infile.IsZombie():
        raise RuntimeError, "Couldn't open %s" % toOpen

    # open a subfolder in the root file if needed
    root_dir=''
    if config.has_option(section,'root_dir'):
        root_dir = config.get(section,'root_dir')

    (dirs,th1s) = listDirsNames(infile, root_dir)

    suffix=''
    if config.has_option(section,'suffix'):
        suffix = config.get(section,'suffix','')

    prefix=section
    if config.has_option(section,'prefix'):
        prefix = config.get(section,'prefix')

    # add this to the output file names (like pfShyftAna in old format)
    outfile_suffix=''
    if config.has_option(section,'outfile_suffix'):
        outfile_suffix = config.get(section,'outfile_suffix')

    outfile_prefix='stitched_'
    if config.has_option(section, 'outfile_prefix'):
        outfile_prefix = config.get(section, 'outfile_prefix')

    # if we want to use template shape
    template = getTemplate(infile, config, section)

    good_names = selectDirNames(th1s, config.get(section,'hist_to_read'), suffix)
    if not good_names and not suffix:
        # Try grabbing the other hists
        good_names = selectDirNames(th1s, config.get(section,'hist_to_read'), '_[bcq]')
    # loop over histograms, read them, scale, save to the output file
    # ===========================================
    outfname = config.get(section,'output_folder') + '/' + outfile_prefix + root_dir + outfile_suffix + '.root'
    if outfname in outputFiles:
        outfile = outputFiles[outfname]
        outfile.cd()
    else:
        outfile = ROOT.TFile(outfname, 'RECREATE')
        outputFiles[outfname] = outfile

    outdir = outfile.GetDirectory('')
    (existing_dirs,existing_names) = listDirsNames(outfile, '')
    for hname in good_names:
        hclone = getClone(infile, root_dir, hname)
        # save event counts for future reference
        #print 'raw integral ', hclone.Integral()
        #print 'raw entries ', hclone.GetEntries()
        # get the scale to use
        scale = getScaleHistogram(hclone, nEvents, config, section)
        #print 'scale ', scale
        outhname = recombineName(hname, prefix, suffix)
        hclone.Scale(scale)
        #print 'scaled integral ', hclone.Integral()
        # here we should be able to use templates if needed
        if template != None:
            new_clone = template.Clone()
            new_clone.Scale(hclone.Integral())
            hclone = new_clone

        if outhname in existing_names:
            # add new histogram to existing one
            oldhist = getHist(outfile, "", outhname)
            ##print 'integral before addition ', oldhist.Integral()
            oldhist.Add(hclone)
            ##print 'integral after addition ', oldhist.Integral()
            oldhist.Write(oldhist.GetName(), ROOT.TH1F.kOverwrite)
            #oldhist.Write()
            #print "Updating %s with %s" % (outhname, hclone.GetName())
        else:
            # store this histogram in the output file
            #print "Initializing %s with %s" % (outhname, hclone.GetName())
            hclone.SetName(outhname)
            hclone.SetDirectory(outdir)
            hclone.Write()
            existing_names.append(outhname)

    infile.Close()
    ROOT.gROOT.GetListOfFiles().Remove(infile)
    print    ROOT.gROOT.GetListOfClasses().GetSize()
    print    ROOT.gROOT.GetListOfColors().GetSize()
    print    ROOT.gROOT.GetListOfTypes().GetSize()
    print    ROOT.gROOT.GetListOfGlobals().GetSize()
    print    ROOT.gROOT.GetListOfGlobalFunctions().GetSize()
    print    ROOT.gROOT.GetListOfFiles().GetSize()
    print    ROOT.gROOT.GetListOfMappedFiles().GetSize()
    print    ROOT.gROOT.GetListOfSockets().GetSize()
    print    ROOT.gROOT.GetListOfSecContexts().GetSize()
    print    ROOT.gROOT.GetListOfCanvases().GetSize()
    print    ROOT.gROOT.GetListOfStyles().GetSize()
    print    ROOT.gROOT.GetListOfFunctions().GetSize()
    print    ROOT.gROOT.GetListOfSpecials().GetSize()
    print    ROOT.gROOT.GetListOfGeometries().GetSize()
    print    ROOT.gROOT.GetListOfBrowsers().GetSize()
    print    ROOT.gROOT.GetListOfCleanups().GetSize()
    print    ROOT.gROOT.GetListOfMessageHandlers().GetSize()

for outfile in outputFiles:
    #outputFiles[outfile].Write()
    outputFiles[outfile].Close()

for k in sorted(histogramList):
    currHist = histogramList[k]
    if currHist['scale'] == 1:
        continue
    print "Scaled %s by %s (%.2f*%.2f*%.2f/%.2f)" % (k, currHist['scale'], currHist['xs'], currHist['globalSF'],currHist['lum'],currHist['n_gen'])


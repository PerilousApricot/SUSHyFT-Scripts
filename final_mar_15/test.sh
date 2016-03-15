#!/bin/bash
copyHistograms.py rebin_central2.config test_nominal.root file=templates/prenominal/nominal.root

echo multiRegionFitter.exe central.mrf \
        templateFile=test_nominal3.root \
        output=fitout/test_rebin3 savePlots=1 saveTemplates=1 \
        includefiles=z_diboson_constr.mrf,z_diboson_def.mrf,qcd_sf.mrf \
        includefiles=sm_constr.mrf \
        showcorrelations=1 fitData=1

    multiRegionFitter.exe central.mrf \
        templateFile=test_nominal.root \
        output=fitout/test_rebin savePlots=1 saveTemplates=1 \
        includefiles=z_diboson_constr.mrf,z_diboson_def.mrf,qcd_sf.mrf \
        includefiles=sm_constr.mrf \
        showcorrelations=1 fitData=1
    multiRegionFitter.exe central.mrf \
        templateFile=templates/prenominal/nominal.root \
        output=fitout/test_norebin savePlots=1 saveTemplates=1 \
        includefiles=z_diboson_constr.mrf,z_diboson_def.mrf,qcd_sf.mrf \
        includefiles=sm_constr.mrf \
        showcorrelations=1 fitData=1

plotHistogram.py test_nominal.root plots/inputs/testinput/

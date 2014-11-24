#!/bin/bash

cd ${SHYFT_BASE}/src
cd CLPTemplateMorph/ ; make -j8
cd ../CLPTemplateFitter/ ; make  -j8
cd ../OptionUtils/ ; make -j8
cd ../multiRegionFitter; make install -j8

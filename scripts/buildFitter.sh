#!/bin/bash

cd ${SUSHYFT_BASE}/src
cd CLPTemplateMorph/ ; make install -j8
cd ../CLPTemplateFitter/ ; make install -j8
cd ../OptionUtils/ ; make install -j8
cd ../multiRegionFitter; make install -j8

#!/bin/bash

version=CMSSW_15_1_0
cmsrel $version
cd $version/src
cmsenv
git cms-init
git cms-merge-topic dgaytanv:pepr_${version}
scram b -j 12

git clone git@github.com:mmarchegiani/hgcal_pu_production.git
scram b -j 12

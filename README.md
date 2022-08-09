## Setup Aug 9 2022

```
cmsrel CMSSW_12_1_1
cd CMSSW_12_1_1/src
cmsenv
git cms-init
git remote add thomas-cmssw git@github.com:tklijnsma/cmssw.git
git fetch thomas-cmssw jansmerging:jansmerging
git cms-merge-topic tklijnsma:jansmerging

git clone git@github.com:tklijnsma/hgcal_pu_production.git
scram b -j 10
```
## Setup March 23 2026

```
version=CMSSW_15_1_0
cmsrel $version
cd $version/src
cmsenv
git cms-init
git cms-merge-topic mmarchegiani:pepr-pileup_${version}
scram b -j 12

git clone git@github.com:mmarchegiani/hgcal_pu_production.git
scram b -j 12
```

## How to run

```
# Create a minbias GENSIM event with finecalo

cmsRun cfg_gensim_D110.py thing=minbias n=1 seed=123 outputfile=pileup_gensim.root


# Create a tau/muon GENSIM event with finecalo

cmsRun cfg_gensim_D110.py thing=muon n=1 seed=123 outputfile=muon_gensim.root


# GENSIM -> DIGI -> RECO with on average 3 pileup events per event

cmsRun cfg_digi_D110.py inputFiles=file:muon_gensim.root pu=file:pileup_gensim.root n=10 npuevents=3 outputfile=muon_digi.root

cmsRun cfg_reco_D110.py inputFiles=file:muon_digi.root pu=file:pileup_gensim.root n=10 npuevents=3 outputfile=muon_reco.root


# RECO -> NANOAOD Ntuple; includes the truth merging

cmsRun cfg_nano_D110.py inputFiles=muon_reco.root merge=True outputfile=file:muon_nano.root
```

### Run test with wrapper script
A wrapper script is provided to run the GEN, DIGI, RECO and NANO steps in one shot:

```bash
bash scripts/run_test_electron.sh test_electron
```

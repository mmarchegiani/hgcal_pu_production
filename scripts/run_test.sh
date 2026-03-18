#!/bin/bash

# Check if output directory argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <output_directory>"
    echo "Example: $0 /path/to/output/folder"
    exit 1
fi

OUTPUT_DIR="$1"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Convert to absolute path to avoid issues with relative paths
OUTPUT_DIR=$(realpath "$OUTPUT_DIR")

echo "Saving all output files to: $OUTPUT_DIR"

# Create a minbias GENSIM event with finecalo
cmsRun cfg_gensim_D110.py thing=minbias n=1 seed=123 outputfile="$OUTPUT_DIR/pileup_gensim.root"

# Create a tau/muon GENSIM event with finecalo
cmsRun cfg_gensim_D110.py thing=muon n=1 seed=123 outputfile="$OUTPUT_DIR/muon_gensim.root"

# GENSIM -> DIGI -> RECO with on average 3 pileup events per event
cmsRun cfg_digi_D110.py inputFiles="file:$OUTPUT_DIR/muon_gensim.root" pu="file:$OUTPUT_DIR/pileup_gensim.root" n=10 npuevents=3 outputfile="$OUTPUT_DIR/muon_digi.root"

cmsRun cfg_reco_D110.py inputFiles="file:$OUTPUT_DIR/muon_digi.root" pu="file:$OUTPUT_DIR/pileup_gensim.root" n=10 npuevents=3 outputfile="$OUTPUT_DIR/muon_reco.root"

# RECO -> NANOAOD Ntuple; includes the truth merging
cmsRun cfg_nano_D110.py inputFiles="file:$OUTPUT_DIR/muon_reco.root" merge=True outputfile="file:$OUTPUT_DIR/muon_nano.root"

echo "All files have been saved to: $OUTPUT_DIR"

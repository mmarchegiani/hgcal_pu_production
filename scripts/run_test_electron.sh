#!/bin/bash

# Check if output directory argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <output_directory>"
    echo "Example: $0 /path/to/output/folder"
    exit 1
fi

OUTPUT_DIR="$1"
N=10
N_MINBIAS=100
PU=30
PARTICLE="electron"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Convert to absolute path to avoid issues with relative paths
OUTPUT_DIR=$(realpath "$OUTPUT_DIR")

# Get script directory for validation script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Simulating $N events with an average of $PU pileup interactions per event..."
echo "Saving all output files to: $OUTPUT_DIR"
echo ""

# Function to validate output files
validate_file() {
    local file=$1
    local step_name=$2
    
    python3 "$SCRIPT_DIR/validate_root_file.py" "$file"
    if [ $? -ne 0 ]; then
        echo ""
        echo "❌ Failed $step_name step - output file is invalid or empty"
        exit 1
    fi
}

# Create a minbias GENSIM event with finecalo
echo "⏳ Running GENSIM step (minbias pileup)..."
cmsRun cfg_gensim_D110.py thing=minbias n=$N_MINBIAS seed=123 outputfile="$OUTPUT_DIR/pileup_gensim.root"
if [ $? -ne 0 ]; then
    echo "❌ Failed GENSIM step (minbias)"
    exit 1
fi
validate_file "$OUTPUT_DIR/pileup_gensim.root" "GENSIM (minbias)"
echo ""

# Create an electron GENSIM event with finecalo
echo "⏳ Running GENSIM step (electron signal)..."
cmsRun cfg_gensim_D110.py thing=$PARTICLE n=$N seed=123 outputfile="$OUTPUT_DIR/${PARTICLE}_gensim.root"
if [ $? -ne 0 ]; then
    echo "❌ Failed GENSIM step ($PARTICLE)"
    exit 1
fi
validate_file "$OUTPUT_DIR/${PARTICLE}_gensim.root" "GENSIM ($PARTICLE)"
echo ""

# GENSIM -> DIGI -> RECO with on average 30 pileup events per event
echo "⏳ Running DIGI step..."
cmsRun cfg_digi_D110.py inputFiles="file:$OUTPUT_DIR/${PARTICLE}_gensim.root" pu="file:$OUTPUT_DIR/pileup_gensim.root" n=$N npuevents=$PU outputfile="$OUTPUT_DIR/${PARTICLE}_digi.root"
if [ $? -ne 0 ]; then
    echo "❌ Failed DIGI step"
    exit 1
fi
validate_file "$OUTPUT_DIR/${PARTICLE}_digi.root" "DIGI"
echo ""

echo "⏳ Running RECO step..."
cmsRun cfg_reco_D110.py inputFiles="file:$OUTPUT_DIR/${PARTICLE}_digi.root" pu="file:$OUTPUT_DIR/pileup_gensim.root" n=$N npuevents=$PU outputfile="$OUTPUT_DIR/${PARTICLE}_reco.root"
if [ $? -ne 0 ]; then
    echo "❌ Failed RECO step"
    exit 1
fi
validate_file "$OUTPUT_DIR/${PARTICLE}_reco.root" "RECO"
echo ""

# RECO -> NANOAOD Ntuple; includes the truth merging
echo "⏳ Running NANO step..."
cmsRun cfg_nano_D110.py inputFiles="file:$OUTPUT_DIR/${PARTICLE}_reco.root" merge=True outputfile="file:$OUTPUT_DIR/${PARTICLE}_nano.root"
if [ $? -ne 0 ]; then
    echo "❌ Failed NANO step"
    exit 1
fi
validate_file "$OUTPUT_DIR/${PARTICLE}_nano.root" "NANO"
echo ""

echo "✅ All steps completed successfully!"
echo "All files have been saved to: $OUTPUT_DIR"

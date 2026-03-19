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

# Get script directory for validation script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

# RECO -> NANOAOD Ntuple; includes the truth merging
echo "▶ Running NANO step..."
cmsRun cfg_nano_D110.py inputFiles="file:$OUTPUT_DIR/muon_reco.root" merge=True outputfile="file:$OUTPUT_DIR/muon_nano.root"
if [ $? -ne 0 ]; then
    echo "❌ Failed NANO step"
    exit 1
fi
validate_file "$OUTPUT_DIR/muon_nano.root" "NANO"
echo ""

echo "✓ All steps completed successfully!"
echo "All files have been saved to: $OUTPUT_DIR"

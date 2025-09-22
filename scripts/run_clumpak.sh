#!/bin/bash

# CLUMPAK Analysis Script
# This script runs CLUMPAK for aligning population structure results
# Usage: ./run_clumpak.sh <admixture_dir> <structure_dir> [options]

set -e  # Exit on any error

# Default parameters
OUTPUT_DIR="output/clumpak"
CLUMPAK_URL="http://clumpak.tau.ac.il/bestK.php"
LOCAL_CLUMPAK=""
THRESHOLD=0.8
MIN_K=2
MAX_K=10

# Function to display usage
usage() {
    echo "Usage: $0 <admixture_dir> <structure_dir> [options]"
    echo ""
    echo "Required arguments:"
    echo "  admixture_dir   Directory containing ADMIXTURE results"
    echo "  structure_dir   Directory containing STRUCTURE results"
    echo ""
    echo "Optional arguments:"
    echo "  --output-dir D     Output directory (default: output/clumpak)"
    echo "  --local-clumpak P  Path to local CLUMPAK installation"
    echo "  --threshold F      Similarity threshold for alignment (default: 0.8)"
    echo "  --min-k N         Minimum K value to process (default: 2)"
    echo "  --max-k N         Maximum K value to process (default: 10)"
    echo "  --web             Use CLUMPAK web service (default)"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 output/admixture output/structure"
    echo "  $0 output/admixture output/structure --local-clumpak /path/to/clumpak"
    exit 1
}

# Parse command line arguments
if [ $# -lt 2 ]; then
    usage
fi

ADMIXTURE_DIR="$1"
STRUCTURE_DIR="$2"
shift 2

USE_WEB=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --local-clumpak)
            LOCAL_CLUMPAK="$2"
            USE_WEB=false
            shift 2
            ;;
        --threshold)
            THRESHOLD="$2"
            shift 2
            ;;
        --min-k)
            MIN_K="$2"
            shift 2
            ;;
        --max-k)
            MAX_K="$2"
            shift 2
            ;;
        --web)
            USE_WEB=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate inputs
if [[ ! -d "$ADMIXTURE_DIR" ]]; then
    echo "Error: ADMIXTURE directory not found: $ADMIXTURE_DIR"
    exit 1
fi

if [[ ! -d "$STRUCTURE_DIR" ]]; then
    echo "Error: STRUCTURE directory not found: $STRUCTURE_DIR"
    exit 1
fi

if [[ "$USE_WEB" == false && ! -d "$LOCAL_CLUMPAK" ]]; then
    echo "Error: Local CLUMPAK directory not found: $LOCAL_CLUMPAK"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "=== CLUMPAK Analysis Started ==="
echo "ADMIXTURE results: $ADMIXTURE_DIR"
echo "STRUCTURE results: $STRUCTURE_DIR"
echo "Output directory: $OUTPUT_DIR"
echo "K range: $MIN_K to $MAX_K"
echo "Similarity threshold: $THRESHOLD"
echo "Use web service: $USE_WEB"
if [[ "$USE_WEB" == false ]]; then
    echo "Local CLUMPAK: $LOCAL_CLUMPAK"
fi
echo ""

# Function to prepare ADMIXTURE results for CLUMPAK
prepare_admixture_results() {
    echo "Preparing ADMIXTURE results..."
    local prep_dir="$OUTPUT_DIR/admixture_prepared"
    mkdir -p "$prep_dir"
    
    for K in $(seq $MIN_K $MAX_K); do
        local q_file="$ADMIXTURE_DIR/$(basename $ADMIXTURE_DIR).$K.Q"
        if [[ -f "$q_file" ]]; then
            # CLUMPAK expects specific format - copy and rename if needed
            cp "$q_file" "$prep_dir/K${K}_run1.Q"
            echo "  Prepared K=$K"
        else
            echo "  Warning: ADMIXTURE Q file not found for K=$K: $q_file"
        fi
    done
}

# Function to prepare STRUCTURE results for CLUMPAK
prepare_structure_results() {
    echo "Preparing STRUCTURE results..."
    local prep_dir="$OUTPUT_DIR/structure_prepared"
    mkdir -p "$prep_dir"
    
    for K in $(seq $MIN_K $MAX_K); do
        local struct_k_dir="$STRUCTURE_DIR/K$K"
        if [[ -d "$struct_k_dir" ]]; then
            local run_count=0
            for out_file in "$struct_k_dir"/*_out_f; do
                if [[ -f "$out_file" ]]; then
                    ((run_count++))
                    # Extract Q matrix from STRUCTURE output
                    # [TO BE FILLED] - Add STRUCTURE output parsing
                    echo "    # [TO BE FILLED] - Parse STRUCTURE output: $out_file"
                    echo "    # Extract Q matrix and save as K${K}_run${run_count}.Q"
                fi
            done
            echo "  Prepared K=$K ($run_count runs)"
        else
            echo "  Warning: STRUCTURE results not found for K=$K: $struct_k_dir"
        fi
    done
}

# Function to run CLUMPAK locally
run_clumpak_local() {
    echo "Running CLUMPAK locally..."
    
    # [TO BE FILLED] - Add local CLUMPAK execution
    echo "# [TO BE FILLED] - Local CLUMPAK command will be added here"
    echo "# This will include:"
    echo "# 1. Setting up CLUMPAK environment"
    echo "# 2. Running bestK analysis"
    echo "# 3. Running main clustering alignment"
    echo "# 4. Processing output files"
    
    local clumpak_cmd="$LOCAL_CLUMPAK/CLUMPAK.pl"
    if [[ -f "$clumpak_cmd" ]]; then
        echo "Found CLUMPAK executable: $clumpak_cmd"
        # Add actual command here
    else
        echo "Error: CLUMPAK executable not found: $clumpak_cmd"
        exit 1
    fi
}

# Function to run CLUMPAK via web service
run_clumpak_web() {
    echo "Running CLUMPAK via web service..."
    echo "Web URL: $CLUMPAK_URL"
    
    # [TO BE FILLED] - Add web service interaction
    echo "# [TO BE FILLED] - Web service submission will be added here"
    echo "# This will include:"
    echo "# 1. Preparing ZIP files for upload"
    echo "# 2. Submitting jobs to CLUMPAK web service"
    echo "# 3. Monitoring job status"
    echo "# 4. Downloading results"
    echo "# 5. Extracting and organizing output"
    
    # Placeholder for web service interaction
    echo "Note: Web service requires manual submission at: $CLUMPAK_URL"
    echo "Please upload the prepared files and download results manually."
}

# Function to create comparison summary
create_comparison_summary() {
    echo "Creating method comparison summary..."
    
    local summary_file="$OUTPUT_DIR/method_comparison.txt"
    cat > "$summary_file" << EOF
# Population Structure Analysis - Method Comparison Summary
# Generated on $(date)

## Input Data
ADMIXTURE results: $ADMIXTURE_DIR
STRUCTURE results: $STRUCTURE_DIR
K range: $MIN_K to $MAX_K
Similarity threshold: $THRESHOLD

## CLUMPAK Alignment Results
# [TO BE FILLED] - Results summary will be populated after CLUMPAK analysis

## Optimal K Selection
# ADMIXTURE (Cross-validation):
# [TO BE FILLED] - Best K from CV errors

# STRUCTURE (Log-likelihood):
# [TO BE FILLED] - Best K from LnP(D)

# CLUMPAK (Best K):
# [TO BE FILLED] - Consensus best K

## Method Concordance
# [TO BE FILLED] - Similarity scores between methods for each K

## Recommendations
# [TO BE FILLED] - Final recommendations based on all analyses
EOF

    echo "Summary template created: $summary_file"
}

# Main analysis workflow
echo "Step 1: Preparing input files for CLUMPAK..."
prepare_admixture_results
prepare_structure_results

echo ""
echo "Step 2: Running CLUMPAK alignment..."
if [[ "$USE_WEB" == true ]]; then
    run_clumpak_web
else
    run_clumpak_local
fi

echo ""
echo "Step 3: Creating comparison summary..."
create_comparison_summary

# [TO BE FILLED] - Post-processing steps
echo ""
echo "Step 4: Post-processing results..."
echo "# [TO BE FILLED] - Add post-processing:"
echo "# 1. Parse CLUMPAK output files"
echo "# 2. Extract aligned Q matrices"
echo "# 3. Calculate similarity metrics"
echo "# 4. Generate consensus results"
echo "# 5. Create visualization input files"

echo ""
echo "=== CLUMPAK Analysis Summary ==="
echo "Prepared files location:"
echo "  ADMIXTURE: $OUTPUT_DIR/admixture_prepared/"
echo "  STRUCTURE: $OUTPUT_DIR/structure_prepared/"
echo ""
echo "Output will be saved in: $OUTPUT_DIR"
echo ""

if [[ "$USE_WEB" == true ]]; then
    echo "NEXT STEPS (Web Service):"
    echo "1. Visit: $CLUMPAK_URL"
    echo "2. Upload prepared Q files"
    echo "3. Download results to: $OUTPUT_DIR"
    echo "4. Run visualization: Rscript scripts/visualize_results.R"
else
    echo "NEXT STEPS (Local):"
    echo "1. Review CLUMPAK output in: $OUTPUT_DIR"
    echo "2. Run visualization: Rscript scripts/visualize_results.R"
fi

echo ""
echo "Files prepared for CLUMPAK:"
echo "ADMIXTURE files:"
ls -la "$OUTPUT_DIR/admixture_prepared/" 2>/dev/null || echo "  No files found"
echo ""
echo "STRUCTURE files:"
ls -la "$OUTPUT_DIR/structure_prepared/" 2>/dev/null || echo "  No files found"
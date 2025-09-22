#!/bin/bash

# ADMIXTURE Analysis Script
# This script runs ADMIXTURE for population structure analysis
# Usage: ./run_admixture.sh <input_prefix> <min_k> <max_k> [options]

set -e  # Exit on any error

# Default parameters
THREADS=4
CV_FOLDS=10
OUTPUT_DIR="output/admixture"
SUPERVISED=false
SEED=12345

# Function to display usage
usage() {
    echo "Usage: $0 <input_prefix> <min_k> <max_k> [options]"
    echo ""
    echo "Required arguments:"
    echo "  input_prefix    Path to PLINK files without extension (e.g., data/sample)"
    echo "  min_k          Minimum number of ancestral populations (e.g., 2)"
    echo "  max_k          Maximum number of ancestral populations (e.g., 10)"
    echo ""
    echo "Optional arguments:"
    echo "  --threads N     Number of threads to use (default: 4)"
    echo "  --cv-folds N    Number of cross-validation folds (default: 10)"
    echo "  --output-dir D  Output directory (default: output/admixture)"
    echo "  --supervised    Run supervised analysis (requires population labels)"
    echo "  --seed N        Random seed (default: 12345)"
    echo "  --help         Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 example_data/1000genomes/sample 2 10 --threads 8"
    exit 1
}

# Parse command line arguments
if [ $# -lt 3 ]; then
    usage
fi

INPUT_PREFIX="$1"
MIN_K="$2"
MAX_K="$3"
shift 3

while [[ $# -gt 0 ]]; do
    case $1 in
        --threads)
            THREADS="$2"
            shift 2
            ;;
        --cv-folds)
            CV_FOLDS="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --supervised)
            SUPERVISED=true
            shift
            ;;
        --seed)
            SEED="$2"
            shift 2
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
if [[ ! -f "${INPUT_PREFIX}.bed" ]]; then
    echo "Error: Input file ${INPUT_PREFIX}.bed not found"
    exit 1
fi

if [[ ! -f "${INPUT_PREFIX}.bim" ]]; then
    echo "Error: Input file ${INPUT_PREFIX}.bim not found"
    exit 1
fi

if [[ ! -f "${INPUT_PREFIX}.fam" ]]; then
    echo "Error: Input file ${INPUT_PREFIX}.fam not found"
    exit 1
fi

if ! command -v admixture &> /dev/null; then
    echo "Error: ADMIXTURE not found in PATH"
    echo "Please install ADMIXTURE and ensure it's in your PATH"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "=== ADMIXTURE Analysis Started ==="
echo "Input prefix: $INPUT_PREFIX"
echo "K range: $MIN_K to $MAX_K"
echo "Threads: $THREADS"
echo "CV folds: $CV_FOLDS"
echo "Output directory: $OUTPUT_DIR"
echo "Supervised: $SUPERVISED"
echo "Random seed: $SEED"
echo ""

# Get the base name for output files
BASENAME=$(basename "$INPUT_PREFIX")

# Initialize CV error file
CV_ERROR_FILE="$OUTPUT_DIR/cv_errors.txt"
echo "K CV_Error" > "$CV_ERROR_FILE"

# Run ADMIXTURE for each K value
for K in $(seq $MIN_K $MAX_K); do
    echo "Running ADMIXTURE for K=$K..."
    
    # Prepare ADMIXTURE command
    ADMIXTURE_CMD="admixture"
    
    if [ "$SUPERVISED" = true ]; then
        ADMIXTURE_CMD="$ADMIXTURE_CMD --supervised"
    fi
    
    ADMIXTURE_CMD="$ADMIXTURE_CMD --cv=$CV_FOLDS"
    ADMIXTURE_CMD="$ADMIXTURE_CMD --seed=$SEED"
    ADMIXTURE_CMD="$ADMIXTURE_CMD -j$THREADS"
    ADMIXTURE_CMD="$ADMIXTURE_CMD ${INPUT_PREFIX}.bed $K"
    
    # Run ADMIXTURE and capture CV error
    cd "$OUTPUT_DIR"
    CV_OUTPUT=$(eval $ADMIXTURE_CMD 2>&1)
    cd - > /dev/null
    
    # Extract CV error from output
    CV_ERROR=$(echo "$CV_OUTPUT" | grep -oP 'CV error \(K=\d+\): \K[\d.]+' || echo "NA")
    echo "$K $CV_ERROR" >> "$CV_ERROR_FILE"
    
    # Move output files to organized structure
    if [ -f "$OUTPUT_DIR/${BASENAME}.$K.Q" ]; then
        echo "✓ K=$K completed successfully (CV error: $CV_ERROR)"
    else
        echo "✗ K=$K failed"
        echo "ADMIXTURE output:"
        echo "$CV_OUTPUT"
    fi
    
    echo ""
done

echo "=== ADMIXTURE Analysis Completed ==="
echo "Results saved in: $OUTPUT_DIR"
echo "CV errors saved in: $CV_ERROR_FILE"
echo ""

# Display best K based on CV error
echo "Cross-validation results:"
echo "K       CV_Error"
cat "$CV_ERROR_FILE" | tail -n +2 | sort -k2 -n | head -5

# [TO BE FILLED] - Add post-processing steps:
# - Generate summary statistics
# - Create initial plots
# - Validate output formats
# - Check for convergence issues

echo ""
echo "Next steps:"
echo "1. Review CV errors to select optimal K"
echo "2. Run STRUCTURE analysis: ./scripts/run_structure.sh"
echo "3. Align results with CLUMPAK: ./scripts/run_clumpak.sh"
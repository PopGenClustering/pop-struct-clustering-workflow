#!/bin/bash

# Master Population Structure Clustering Pipeline
# This script orchestrates the complete workflow from data input to visualization
# Usage: ./pipeline.sh <input_prefix> <min_k> <max_k> [options]

set -e  # Exit on any error

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default parameters
THREADS=4
STRUCTURE_RUNS=10
ADMIXTURE_CV=10
OUTPUT_BASE="output"
SKIP_ADMIXTURE=false
SKIP_STRUCTURE=false
SKIP_CLUMPAK=false
SKIP_VISUALIZATION=false
CLEANUP_TEMP=true
VERBOSE=true

# Function to display usage
usage() {
    echo "Population Structure Clustering Pipeline"
    echo "Usage: $0 <input_prefix> <min_k> <max_k> [options]"
    echo ""
    echo "Required arguments:"
    echo "  input_prefix    Path to PLINK files without extension (e.g., data/sample)"
    echo "  min_k          Minimum number of clusters (e.g., 2)"
    echo "  max_k          Maximum number of clusters (e.g., 10)"
    echo ""
    echo "Optional arguments:"
    echo "  --threads N          Number of threads to use (default: 4)"
    echo "  --structure-runs N   Number of STRUCTURE runs per K (default: 10)"
    echo "  --admixture-cv N     Cross-validation folds for ADMIXTURE (default: 10)"
    echo "  --output-base D      Base output directory (default: output)"
    echo "  --skip-admixture     Skip ADMIXTURE analysis"
    echo "  --skip-structure     Skip STRUCTURE analysis"
    echo "  --skip-clumpak       Skip CLUMPAK alignment"
    echo "  --skip-visualization Skip visualization step"
    echo "  --no-cleanup         Keep temporary files"
    echo "  --quiet             Reduce output verbosity"
    echo "  --help              Show this help message"
    echo ""
    echo "Analysis Steps:"
    echo "  1. Data validation and preprocessing"
    echo "  2. ADMIXTURE analysis (fast, cross-validation)"
    echo "  3. STRUCTURE analysis (Bayesian, multiple runs)"
    echo "  4. CLUMPAK alignment and comparison"
    echo "  5. Comprehensive visualization"
    echo ""
    echo "Examples:"
    echo "  # Basic analysis"
    echo "  $0 example_data/1000genomes/sample 2 10"
    echo ""
    echo "  # High-performance analysis"
    echo "  $0 data/my_samples 2 8 --threads 16 --structure-runs 20"
    echo ""
    echo "  # Quick ADMIXTURE-only analysis"
    echo "  $0 data/my_samples 2 10 --skip-structure --skip-clumpak"
    exit 1
}

# Function to log messages
log_message() {
    if [[ "$VERBOSE" == true ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    fi
}

# Function to log errors
log_error() {
    echo "[ERROR $(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

# Function to check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Required command '$1' not found in PATH"
        return 1
    fi
    return 0
}

# Function to validate input files
validate_inputs() {
    log_message "Validating input files..."
    
    local prefix="$1"
    local errors=0
    
    for ext in bed bim fam; do
        if [[ ! -f "${prefix}.${ext}" ]]; then
            log_error "Input file not found: ${prefix}.${ext}"
            ((errors++))
        fi
    done
    
    if [[ $errors -gt 0 ]]; then
        log_error "Input validation failed. Missing $errors file(s)."
        return 1
    fi
    
    # Check file sizes and basic format
    local bed_size=$(stat -c%s "${prefix}.bed" 2>/dev/null || echo 0)
    local bim_lines=$(wc -l < "${prefix}.bim" 2>/dev/null || echo 0)
    local fam_lines=$(wc -l < "${prefix}.fam" 2>/dev/null || echo 0)
    
    log_message "Input summary:"
    log_message "  BED file size: ${bed_size} bytes"
    log_message "  Number of variants: ${bim_lines}"
    log_message "  Number of individuals: ${fam_lines}"
    
    if [[ $bed_size -lt 100 ]] || [[ $bim_lines -lt 10 ]] || [[ $fam_lines -lt 5 ]]; then
        log_error "Input files appear to be too small or empty"
        return 1
    fi
    
    return 0
}

# Function to check software dependencies
check_dependencies() {
    log_message "Checking software dependencies..."
    
    local missing_software=()
    
    if [[ "$SKIP_ADMIXTURE" == false ]]; then
        check_command "admixture" || missing_software+=("admixture")
    fi
    
    if [[ "$SKIP_STRUCTURE" == false ]]; then
        check_command "structure" || missing_software+=("structure")
    fi
    
    if [[ "$SKIP_VISUALIZATION" == false ]]; then
        check_command "Rscript" || missing_software+=("R/Rscript")
    fi
    
    # Always need basic tools
    check_command "awk" || missing_software+=("awk")
    check_command "grep" || missing_software+=("grep")
    
    if [[ ${#missing_software[@]} -gt 0 ]]; then
        log_error "Missing required software: ${missing_software[*]}"
        log_error "Please install missing software and ensure it's in your PATH"
        return 1
    fi
    
    log_message "All required software found"
    return 0
}

# Function to estimate runtime
estimate_runtime() {
    local min_k="$1"
    local max_k="$2"
    local fam_lines="$3"
    local bim_lines="$4"
    
    log_message "Estimating runtime..."
    
    # Rough estimates (very approximate)
    local k_range=$((max_k - min_k + 1))
    local admixture_time=$((k_range * fam_lines * bim_lines / 1000000))  # Very rough
    local structure_time=$((k_range * STRUCTURE_RUNS * fam_lines / 100))  # Very rough
    
    log_message "Estimated runtime:"
    log_message "  ADMIXTURE: ~${admixture_time} minutes"
    log_message "  STRUCTURE: ~${structure_time} minutes"
    log_message "  Total: ~$((admixture_time + structure_time + 10)) minutes"
    log_message ""
    log_message "Note: These are rough estimates and actual time may vary significantly"
}

# Function to create output directory structure
setup_output_directories() {
    log_message "Setting up output directories..."
    
    mkdir -p "$OUTPUT_BASE"/{admixture,structure,clumpak,visualization}
    mkdir -p "$OUTPUT_BASE"/logs
    
    # Create analysis log
    local log_file="$OUTPUT_BASE/logs/pipeline_$(date +%Y%m%d_%H%M%S).log"
    echo "Pipeline started: $(date)" > "$log_file"
    echo "Command: $0 $*" >> "$log_file"
    echo "Working directory: $(pwd)" >> "$log_file"
    echo "" >> "$log_file"
    
    echo "$log_file"  # Return log file path
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
        --structure-runs)
            STRUCTURE_RUNS="$2"
            shift 2
            ;;
        --admixture-cv)
            ADMIXTURE_CV="$2"
            shift 2
            ;;
        --output-base)
            OUTPUT_BASE="$2"
            shift 2
            ;;
        --skip-admixture)
            SKIP_ADMIXTURE=true
            shift
            ;;
        --skip-structure)
            SKIP_STRUCTURE=true
            shift
            ;;
        --skip-clumpak)
            SKIP_CLUMPAK=true
            shift
            ;;
        --skip-visualization)
            SKIP_VISUALIZATION=true
            shift
            ;;
        --no-cleanup)
            CLEANUP_TEMP=false
            shift
            ;;
        --quiet)
            VERBOSE=false
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

# Validate K range
if [[ $MIN_K -ge $MAX_K ]] || [[ $MIN_K -lt 1 ]] || [[ $MAX_K -gt 20 ]]; then
    log_error "Invalid K range: $MIN_K to $MAX_K"
    log_error "MIN_K must be >= 1, MAX_K must be <= 20, and MIN_K < MAX_K"
    exit 1
fi

# Start pipeline
echo "========================================================"
echo "Population Structure Clustering Pipeline"
echo "========================================================"
echo "Input: $INPUT_PREFIX"
echo "K range: $MIN_K to $MAX_K"
echo "Threads: $THREADS"
echo "Output: $OUTPUT_BASE"
echo "========================================================"
echo ""

# Setup
LOG_FILE=$(setup_output_directories)
log_message "Pipeline log: $LOG_FILE"

# Pre-flight checks
log_message "Performing pre-flight checks..."
validate_inputs "$INPUT_PREFIX" || exit 1
check_dependencies || exit 1

# Get data dimensions for estimates
FAM_LINES=$(wc -l < "${INPUT_PREFIX}.fam")
BIM_LINES=$(wc -l < "${INPUT_PREFIX}.bim")
estimate_runtime "$MIN_K" "$MAX_K" "$FAM_LINES" "$BIM_LINES"

echo ""
read -p "Continue with analysis? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_message "Analysis cancelled by user"
    exit 0
fi

# Step 1: ADMIXTURE Analysis
if [[ "$SKIP_ADMIXTURE" == false ]]; then
    echo ""
    log_message "=========================================="
    log_message "Step 1: Running ADMIXTURE Analysis"
    log_message "=========================================="
    
    ADMIXTURE_CMD="$SCRIPT_DIR/run_admixture.sh"
    ADMIXTURE_CMD="$ADMIXTURE_CMD \"$INPUT_PREFIX\" $MIN_K $MAX_K"
    ADMIXTURE_CMD="$ADMIXTURE_CMD --threads $THREADS"
    ADMIXTURE_CMD="$ADMIXTURE_CMD --cv-folds $ADMIXTURE_CV"
    ADMIXTURE_CMD="$ADMIXTURE_CMD --output-dir \"$OUTPUT_BASE/admixture\""
    
    log_message "Running: $ADMIXTURE_CMD"
    if eval $ADMIXTURE_CMD; then
        log_message "✓ ADMIXTURE analysis completed successfully"
    else
        log_error "✗ ADMIXTURE analysis failed"
        exit 1
    fi
else
    log_message "Skipping ADMIXTURE analysis"
fi

# Step 2: STRUCTURE Analysis
if [[ "$SKIP_STRUCTURE" == false ]]; then
    echo ""
    log_message "=========================================="
    log_message "Step 2: Running STRUCTURE Analysis"
    log_message "=========================================="
    
    STRUCTURE_CMD="$SCRIPT_DIR/run_structure.sh"
    STRUCTURE_CMD="$STRUCTURE_CMD \"$INPUT_PREFIX\" $MIN_K $MAX_K"
    STRUCTURE_CMD="$STRUCTURE_CMD --runs $STRUCTURE_RUNS"
    STRUCTURE_CMD="$STRUCTURE_CMD --output-dir \"$OUTPUT_BASE/structure\""
    
    log_message "Running: $STRUCTURE_CMD"
    if eval $STRUCTURE_CMD; then
        log_message "✓ STRUCTURE analysis completed successfully"
    else
        log_error "✗ STRUCTURE analysis failed"
        exit 1
    fi
else
    log_message "Skipping STRUCTURE analysis"
fi

# Step 3: CLUMPAK Alignment
if [[ "$SKIP_CLUMPAK" == false ]]; then
    echo ""
    log_message "=========================================="
    log_message "Step 3: Running CLUMPAK Alignment"
    log_message "=========================================="
    
    CLUMPAK_CMD="$SCRIPT_DIR/run_clumpak.sh"
    CLUMPAK_CMD="$CLUMPAK_CMD \"$OUTPUT_BASE/admixture\" \"$OUTPUT_BASE/structure\""
    CLUMPAK_CMD="$CLUMPAK_CMD --output-dir \"$OUTPUT_BASE/clumpak\""
    CLUMPAK_CMD="$CLUMPAK_CMD --min-k $MIN_K --max-k $MAX_K"
    
    log_message "Running: $CLUMPAK_CMD"
    if eval $CLUMPAK_CMD; then
        log_message "✓ CLUMPAK alignment completed successfully"
    else
        log_error "✗ CLUMPAK alignment failed"
        exit 1
    fi
else
    log_message "Skipping CLUMPAK alignment"
fi

# Step 4: Visualization
if [[ "$SKIP_VISUALIZATION" == false ]]; then
    echo ""
    log_message "=========================================="
    log_message "Step 4: Creating Visualizations"
    log_message "=========================================="
    
    VIZ_INPUT="$OUTPUT_BASE/clumpak"
    if [[ "$SKIP_CLUMPAK" == true ]]; then
        VIZ_INPUT="$OUTPUT_BASE/admixture"
    fi
    
    VIZ_CMD="Rscript $SCRIPT_DIR/visualize_results.R"
    VIZ_CMD="$VIZ_CMD \"$VIZ_INPUT\""
    VIZ_CMD="$VIZ_CMD --output-dir \"$OUTPUT_BASE/visualization\""
    
    log_message "Running: $VIZ_CMD"
    if eval $VIZ_CMD; then
        log_message "✓ Visualization completed successfully"
    else
        log_error "✗ Visualization failed"
        exit 1
    fi
else
    log_message "Skipping visualization"
fi

# Step 5: Generate Summary Report
echo ""
log_message "=========================================="
log_message "Step 5: Generating Summary Report"
log_message "=========================================="

SUMMARY_FILE="$OUTPUT_BASE/analysis_summary.txt"
cat > "$SUMMARY_FILE" << EOF
Population Structure Clustering Analysis Summary
===============================================
Generated on: $(date)
Pipeline version: 1.0

Input Data:
  File prefix: $INPUT_PREFIX
  Individuals: $FAM_LINES
  Variants: $BIM_LINES

Analysis Parameters:
  K range: $MIN_K to $MAX_K
  Threads: $THREADS
  ADMIXTURE CV folds: $ADMIXTURE_CV
  STRUCTURE runs per K: $STRUCTURE_RUNS

Steps Completed:
  ADMIXTURE: $([ "$SKIP_ADMIXTURE" == false ] && echo "✓" || echo "✗ (skipped)")
  STRUCTURE: $([ "$SKIP_STRUCTURE" == false ] && echo "✓" || echo "✗ (skipped)")
  CLUMPAK: $([ "$SKIP_CLUMPAK" == false ] && echo "✓" || echo "✗ (skipped)")
  Visualization: $([ "$SKIP_VISUALIZATION" == false ] && echo "✓" || echo "✗ (skipped)")

Output Structure:
  Base directory: $OUTPUT_BASE/
  ├── admixture/     - ADMIXTURE results and CV errors
  ├── structure/     - STRUCTURE results by K value
  ├── clumpak/       - Aligned and compared results
  ├── visualization/ - Publication-ready plots
  └── logs/          - Analysis logs

Next Steps:
1. Review CV errors in admixture/cv_errors.txt to select optimal K
2. Examine structure bar plots in visualization/ directory
3. Compare results between methods using CLUMPAK output
4. Customize visualizations for publication if needed

For questions or issues, see the repository README.md
EOF

log_message "Summary report saved: $SUMMARY_FILE"

# Cleanup temporary files if requested
if [[ "$CLEANUP_TEMP" == true ]]; then
    log_message "Cleaning up temporary files..."
    # [TO BE FILLED] - Add cleanup commands for specific temporary files
    find "$OUTPUT_BASE" -name "*.tmp" -delete 2>/dev/null || true
    find "$OUTPUT_BASE" -name "core.*" -delete 2>/dev/null || true
fi

# Final summary
echo ""
echo "========================================================"
echo "Pipeline Completed Successfully!"
echo "========================================================"
echo "Total runtime: $(date)"
echo "Output directory: $OUTPUT_BASE"
echo "Summary report: $SUMMARY_FILE"
echo ""
echo "Key files to review:"
echo "  • Cross-validation errors: $OUTPUT_BASE/admixture/cv_errors.txt"
echo "  • Structure plots: $OUTPUT_BASE/visualization/"
echo "  • Complete summary: $SUMMARY_FILE"
echo ""
echo "Next steps:"
echo "  1. Review the analysis summary"
echo "  2. Examine plots to select optimal K"
echo "  3. Interpret population structure results"
echo "========================================================"
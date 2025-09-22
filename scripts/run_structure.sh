#!/bin/bash

# STRUCTURE Analysis Script
# This script runs STRUCTURE for population structure analysis
# Usage: ./run_structure.sh <input_prefix> <min_k> <max_k> [options]

set -e  # Exit on any error

# Default parameters
BURNIN=10000
NUMREPS=20000
RUNS_PER_K=10
OUTPUT_DIR="output/structure"
ADMIXALPHA=1.0
ALLELEFREQCORRELATED=1
POPFLAG=0
SEED=12345

# Function to display usage
usage() {
    echo "Usage: $0 <input_prefix> <min_k> <max_k> [options]"
    echo ""
    echo "Required arguments:"
    echo "  input_prefix    Path to PLINK files without extension (e.g., data/sample)"
    echo "  min_k          Minimum number of populations (e.g., 2)"
    echo "  max_k          Maximum number of populations (e.g., 10)"
    echo ""
    echo "Optional arguments:"
    echo "  --burnin N      Number of burnin iterations (default: 10000)"
    echo "  --numreps N     Number of MCMC iterations (default: 20000)"
    echo "  --runs N        Number of independent runs per K (default: 10)"
    echo "  --output-dir D  Output directory (default: output/structure)"
    echo "  --admixalpha F  Alpha parameter for admixture model (default: 1.0)"
    echo "  --correlated    Use correlated allele frequency model (default)"
    echo "  --independent   Use independent allele frequency model"
    echo "  --popflag N     Use population flag (0=no, 1=yes, default: 0)"
    echo "  --seed N        Random seed (default: 12345)"
    echo "  --help         Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 example_data/1000genomes/sample 2 10 --burnin 20000 --numreps 40000"
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
        --burnin)
            BURNIN="$2"
            shift 2
            ;;
        --numreps)
            NUMREPS="$2"
            shift 2
            ;;
        --runs)
            RUNS_PER_K="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --admixalpha)
            ADMIXALPHA="$2"
            shift 2
            ;;
        --correlated)
            ALLELEFREQCORRELATED=1
            shift
            ;;
        --independent)
            ALLELEFREQCORRELATED=0
            shift
            ;;
        --popflag)
            POPFLAG="$2"
            shift 2
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

if ! command -v structure &> /dev/null; then
    echo "Error: STRUCTURE not found in PATH"
    echo "Please install STRUCTURE and ensure it's in your PATH"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "=== STRUCTURE Analysis Started ==="
echo "Input prefix: $INPUT_PREFIX"
echo "K range: $MIN_K to $MAX_K"
echo "Burnin: $BURNIN"
echo "MCMC reps: $NUMREPS"
echo "Runs per K: $RUNS_PER_K"
echo "Output directory: $OUTPUT_DIR"
echo "Admixture alpha: $ADMIXALPHA"
echo "Correlated freqs: $ALLELEFREQCORRELATED"
echo "Population flag: $POPFLAG"
echo "Random seed: $SEED"
echo ""

# Convert PLINK to STRUCTURE format
echo "Converting PLINK to STRUCTURE format..."
BASENAME=$(basename "$INPUT_PREFIX")
STRUCTURE_INPUT="$OUTPUT_DIR/${BASENAME}_structure.txt"

# [TO BE FILLED] - Add PLINK to STRUCTURE conversion
# This section will contain code to convert PLINK binary format to STRUCTURE input format
echo "# [TO BE FILLED] - PLINK to STRUCTURE format conversion"
echo "# Command will be added here to convert:"
echo "# ${INPUT_PREFIX}.bed/bim/fam -> $STRUCTURE_INPUT"

# Count individuals and loci for parameter file
# [TO BE FILLED] - Extract these values from the converted data
NUMINDS=100  # Placeholder - will be extracted from data
NUMLOCI=1000 # Placeholder - will be extracted from data

echo "Individuals: $NUMINDS"
echo "Loci: $NUMLOCI"
echo ""

# Function to create STRUCTURE parameter file
create_mainparams() {
    local k=$1
    local run=$2
    local params_file="$OUTPUT_DIR/K${k}_run${run}_mainparams"
    
    cat > "$params_file" << EOF
#define MAXPOPS    $k        // Number of populations assumed
#define BURNIN     $BURNIN   // Length of burnin period
#define NUMREPS    $NUMREPS  // Number of MCMC reps after burnin

#define INFILE     $STRUCTURE_INPUT    // Input filename
#define OUTFILE    $OUTPUT_DIR/K${k}_run${run}_out  // Output filename

#define NUMINDS    $NUMINDS  // Number of individuals
#define NUMLOCI    $NUMLOCI  // Number of loci
#define MISSING    -9        // Value given to missing genotype data
#define ONEROWPERIND 0       // 0=two rows per ind; 1=one row per ind

#define LABEL      1         // Use labels for individuals
#define POPDATA    $POPFLAG  // Use population data
#define POPFLAG    0         // Use population flag
#define LOCDATA    0         // Use location data
#define PHENOTYPE  0         // Use phenotype data
#define EXTRACOLS  0         // Number of extra columns
#define MARKERNAMES 1        // Use marker names

#define MAPDISTANCES 0       // Use map distances
#define ONEROWPERIND 0       // 0=two rows per ind

// Advanced model options
#define NOADMIX     0        // Use admixture model
#define LINKAGE     0        // Use linkage model
#define USEPOPINFO  0        // Use population info to test for migrants
#define LOCPRIOR    0        // Use location prior

#define FREQSCORR   $ALLELEFREQCORRELATED  // Allele frequencies correlated
#define ONEFST      0        // Assume same value of Fst for all subpopulations

#define INFERALPHA  1        // Infer ALPHA (degree of admixture)
#define POPALPHAS   0        // Separate alpha for each population
#define ALPHA       $ADMIXALPHA  // Dirichlet parameter for degree of admixture

#define INFERLAMBDA 0        // Infer LAMBDA (allele freq prior)
#define POPSPECIFICLAMBDA 0  // Different lambda for each population
#define LAMBDA      1.0      // Dirichlet parameter for allele frequencies
EOF
}

# Function to create STRUCTURE extraparams file
create_extraparams() {
    local k=$1
    local run=$2
    local params_file="$OUTPUT_DIR/K${k}_run${run}_extraparams"
    
    cat > "$params_file" << EOF
#define PLOIDY      2        // Ploidy of data
#define RECESSIVEALLELES 0   // Treat alleles as recessive
#define PHASEINFO   0        // Use phase information
#define PHASED      0        // Data is phased

// Advanced options
#define RANDOMIZE   1        // Randomize order of individuals
#define SEED        $SEED    // Random number seed
#define METROFREQ   10       // Frequency of Metropolis update

// Output options
#define PRINTQHAT   1        // Print Q-hat (individual ancestry)
#define PRINTQSUM   1        // Print Q-sum 
#define PRINTFHAT   1        // Print F-hat (allele frequencies)
#define PRINTFSUM   1        // Print F-sum

// Convergence
#define ANCESTDIST  0        // Use ancestral distance
#define STARTATPOPINFO 0     // Start at popinfo
#define COMPUTEPROB 1        // Compute probability of data
#define PFROMPOPFLAGONLY 0   // Use pop flag only
EOF
}

# Run STRUCTURE for each K value
for K in $(seq $MIN_K $MAX_K); do
    echo "Running STRUCTURE for K=$K..."
    mkdir -p "$OUTPUT_DIR/K$K"
    
    # Run multiple independent runs for each K
    for RUN in $(seq 1 $RUNS_PER_K); do
        echo "  Run $RUN/$RUNS_PER_K..."
        
        # Create parameter files
        create_mainparams $K $RUN
        create_extraparams $K $RUN
        
        # Run STRUCTURE
        MAIN_PARAMS="$OUTPUT_DIR/K${K}_run${RUN}_mainparams"
        EXTRA_PARAMS="$OUTPUT_DIR/K${K}_run${RUN}_extraparams"
        
        # [TO BE FILLED] - Add actual STRUCTURE command
        echo "# structure -m $MAIN_PARAMS -e $EXTRA_PARAMS"
        echo "# [TO BE FILLED] - Actual STRUCTURE execution will be added here"
        
        # Move output files to K-specific directory
        if [ -f "$OUTPUT_DIR/K${K}_run${RUN}_out_f" ]; then
            mv "$OUTPUT_DIR/K${K}_run${RUN}_out"* "$OUTPUT_DIR/K$K/"
            echo "    ✓ Run $RUN completed"
        else
            echo "    ✗ Run $RUN failed"
        fi
    done
    
    echo "  K=$K completed ($RUNS_PER_K runs)"
    echo ""
done

# [TO BE FILLED] - Post-processing steps:
echo "=== Post-processing STRUCTURE results ==="
echo "# [TO BE FILLED] - Add post-processing:"
echo "# 1. Parse log-likelihood values"
echo "# 2. Calculate mean and variance across runs"
echo "# 3. Identify best run for each K"
echo "# 4. Generate summary statistics"

echo "=== STRUCTURE Analysis Completed ==="
echo "Results saved in: $OUTPUT_DIR"
echo ""
echo "Output structure:"
echo "$OUTPUT_DIR/"
for K in $(seq $MIN_K $MAX_K); do
    echo "  K$K/ - Results for K=$K ($RUNS_PER_K runs)"
done

echo ""
echo "Next steps:"
echo "1. Review log-likelihood values to assess convergence"
echo "2. Run CLUMPAK to align results: ./scripts/run_clumpak.sh"
echo "3. Compare with ADMIXTURE results"

# [TO BE FILLED] - Add convergence diagnostics and result summary
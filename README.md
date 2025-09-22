# Population Structure Clustering Workflow

This repository provides a comprehensive tutorial and workflow for performing population structure clustering analysis using multiple complementary tools. This guide walks you through the entire process, from data preparation to creating publication-quality visualizations.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Repository Structure](#repository-structure)
4. [Quick Start](#quick-start)
5. [Data Preparation](#data-preparation)
6. [Analysis Workflow](#analysis-workflow)
   - [Step 0: Data Conversion](#step-0-data-conversion)
   - [Step 1.1: ADMIXTURE Analysis](#step-11-admixture-analysis)
   - [Step 1.2: STRUCTURE Analysis](#step-12-structure-analysis)
   - [Step 2: CLUMPPLING Analysis](#step-2-clumppling-analysis)
   - [Step 3: Visualization](#step-3-visualization)
8. [Automated Pipeline](#automated-pipeline)
9. [Interpreting Results](#interpreting-results)
10. [Troubleshooting](#troubleshooting)
11. [Citations](#citations)

## Overview

Population structure clustering analysis is essential for understanding genetic diversity and ancestry patterns in structured populations. This workflow integrates four key tools:

- **ADMIXTURE**: Fast model-based estimation of ancestry fractions
- **STRUCTURE**: Bayesian clustering method for inferring population structure
- **CLUMPPLING**: Alignment of multiple clustering results across K values
- **Custom Visualization Tools**: Interactive visualization of aligned clustering results

## Prerequisites

### Software Requirements

Before running this workflow, ensure you have the following software installed:

- [*if data conversion is needed*] PLINK (v2.0): see [PLINK 2.0](https://www.cog-genomics.org/plink/2.0); also see [PLINK 1.9](https://www.cog-genomics.org/plink2)
- ADMIXTURE (v1.3.0): see [https://github.com/NovembreLab/admixture](https://github.com/NovembreLab/admixture)
- STRUCTURE (v2.3.4): see [https://web.stanford.edu/group/pritchardlab/structure.html](https://web.stanford.edu/group/pritchardlab/structure.html)
- CLUMPPLING (v2.0), which requires Python (v3.8-v3.12) with designated packages: see [https://github.com/PopGenClustering/Clumppling](https://github.com/PopGenClustering/Clumppling)
- Visualization, which requires Python (v3.x)

Installation instructions are provided separately in **[TO BE FILLED]**.

## Repository Structure

```
pop-struct-clustering-workflow/
├── README.md                     # This tutorial
├── scripts/                      # Analysis scripts
│   ├── run_admixture.sh          # ADMIXTURE analysis script
│   ├── run_structure.sh          # STRUCTURE analysis script
│   ├── run_clumppling.sh         # CLMPPLING analysis script
│   ├── vis.sh                    # Visualization script
│   └── pipeline.sh               # Master pipeline script
├── example_data/                 # Example datasets
│   ├── 1kg_subset/               # 1000 Genomes Project subset
│   └── README.md                 # Data description
├── output/                       # Analysis outputs
│   ├── admixture/                # ADMIXTURE results
│   ├── structure/                # STRUCTURE results
│   ├── clumppling/               # CLUMPPLING results
│   └── visualization/            # Final plots and summaries
└── LICENSE                       # MIT License
```

## Quick Start

For users familiar with population genetics analysis:

```bash
# Clone the repository
git clone https://github.com/PopGenClustering/pop-struct-clustering-workflow.git
cd pop-struct-clustering-workflow

# Run the complete pipeline
./scripts/pipeline.sh example_data/1kg_subset/sample.bed 2 10

# View results
ls output/visualization/
```

## Data Preparation

### Example Data

We provide a subset of the 1000 Genomes Project data for testing:

**[TO BE FILLED]** - Download instructions and data description will be added here.

### Preparing Your Own Data

**[TO BE FILLED]** - Guidelines for formatting your genetic data will be provided here.

## Analysis Workflow

### Step 0: Data Conversion

### Input Data Format

This workflow accepts genetic data in PLINK binary format:
- `.bed` file: Binary genotype data
- `.bim` file: Variant information (chromosome, position, alleles)
- `.fam` file: Sample information (family ID, individual ID, population labels)

If data is in VCF format, run *TODO* to convert it to PLINK format.
**[TO BE FILLED]**

### Step 1.1: ADMIXTURE Analysis

ADMIXTURE performs fast maximum likelihood estimation of individual ancestries.

```bash
# Run ADMIXTURE for K=2 to K=10
./scripts/run_admixture.sh example_data/1kg_subset/sample.bed 2 10
```

**Expected outputs:**
- `output/admixture/sample.K.Q` - Ancestry fractions for each individual
- `output/admixture/sample.K.P` - Allele frequencies for each population

**[TO BE FILLED]** - Detailed parameter explanations and customization options.

### Step 1.2: STRUCTURE Analysis

STRUCTURE uses Bayesian inference to identify population clusters.

```bash
# Run STRUCTURE for K=2 to K=10
./scripts/run_structure.sh example_data/1kg_subset/sample.bed 2 10
```

**Expected outputs:**
- `output/structure/K*/` - Results for each K value
- Parameter files and convergence diagnostics

**[TO BE FILLED]** - STRUCTURE parameter tuning and interpretation guidelines.

### Step 2: CLUMPPLING Analysis

CLUMPPLING aligns clustering solutions across different K values and methods.

```bash
# Align ADMIXTURE and STRUCTURE results
./scripts/run_clumpak.sh output/admixture output/structure
```

**Expected outputs:**
- `output/clumpak/aligned_results/` - Aligned Q matrices
- Clustering comparison summaries

**[TO BE FILLED]** - CLUMPAK configuration and advanced options.

### Step 3: Visualization

Generate publication-quality plots and summaries.

```bash
# Create comprehensive visualizations
Rscript scripts/visualize_results.R output/clumpak/aligned_results/
```

**Expected outputs:**
- Population structure bar plots
- Geographic maps (if coordinates provided)
- Cross-validation plots for model selection
- Comparative analyses between methods

**[TO BE FILLED]** - Customization options for plots and publication formatting.

## Automated Pipeline

For streamlined analysis, use the master pipeline script:

```bash
./scripts/pipeline.sh [INPUT_PREFIX] [MIN_K] [MAX_K] [OPTIONS]
```

**Parameters:**
- `INPUT_PREFIX`: Path to PLINK files without extension (e.g., `data/sample`)
- `MIN_K`: Minimum number of clusters to test
- `MAX_K`: Maximum number of clusters to test
- `OPTIONS`: Additional parameters (see script for details)

**Example:**
```bash
./scripts/pipeline.sh example_data/1kg_subset/sample 2 10 --threads 4 --iterations 10000
```

**[TO BE FILLED]** - Advanced pipeline options and parallel processing setup.

## Interpreting Results

### Model Selection

**[TO BE FILLED]** - Guidelines for choosing optimal K values using cross-validation and other criteria.

### Population Labeling

**[TO BE FILLED]** - Best practices for interpreting ancestry coefficients and population labeling.

### Comparative Analysis

**[TO BE FILLED]** - How to compare results between ADMIXTURE and STRUCTURE.

## Troubleshooting

### Common Issues

**[TO BE FILLED]** - Solutions for frequent problems:
- Memory errors with large datasets
- Convergence issues in STRUCTURE
- Data format problems
- Missing dependencies

### Performance Optimization

**[TO BE FILLED]** - Tips for improving analysis speed and handling large datasets.

## Citations

If you use this workflow in your research, please cite the individual software packages:
- ADMIXTURE: Alexander et al. (2009)
- STRUCTURE: Pritchard et al. (2000)
- CLUMPPLING: Liu et al. (2024)
- Vis.


## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Note**: Sections marked with **[TO BE FILLED]** contain placeholder content that will be expanded with detailed instructions, examples, and best practices.

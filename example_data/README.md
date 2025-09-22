# Example Data - 1000 Genomes Project Subset

This directory contains example genetic data for testing the population structure clustering workflow.

## Data Description

**[TO BE FILLED]** - This section will contain detailed descriptions of the example datasets:

### 1000 Genomes Project Subset

- **File prefix**: `sample`
- **Format**: PLINK binary format (`.bed`, `.bim`, `.fam`)
- **Populations**: Representative samples from major continental populations
- **Markers**: High-quality SNPs for population structure analysis
- **Sample size**: Approximately 100-200 individuals per population

### Files

- `sample.bed` - Binary genotype data
- `sample.bim` - Variant information (chromosome, position, alleles)
- `sample.fam` - Sample information with population labels
- `sample_metadata.txt` - Additional sample metadata
- `population_info.txt` - Population descriptions and geographic coordinates

### Data Preparation

**[TO BE FILLED]** - Instructions for downloading and preparing the example data:

```bash
# Download example data (commands will be added)
# wget [URL_TO_BE_FILLED]
# tar -xzf example_data.tar.gz
```

### Quality Control

The example data has been pre-processed with the following quality control steps:
- Minor allele frequency > 0.05
- Missing data rate < 0.02
- Hardy-Weinberg equilibrium p-value > 1e-6
- Linkage disequilibrium pruning (r² < 0.2)

### Population Groups

**[TO BE FILLED]** - Detailed description of population groups included:

1. **African (AFR)**: YRI, LWK, GWD
2. **European (EUR)**: CEU, TSI, GBR
3. **East Asian (EAS)**: CHB, JPT, CHS
4. **South Asian (SAS)**: GIH, PJL, BEB
5. **Admixed American (AMR)**: MXL, PUR, CLM

### Expected Results

When running the complete workflow on this example data, you should expect:
- Clear population structure corresponding to continental groups
- Optimal K value around 4-5 for major continental populations
- High concordance between ADMIXTURE and STRUCTURE results
- Meaningful geographic clustering patterns

### Citation

If you use this example data in your research, please cite:
- The 1000 Genomes Project Consortium
- This workflow repository

### Custom Data

To use your own data with this workflow:
1. Ensure data is in PLINK binary format
2. Include population labels in the `.fam` file (6th column)
3. Consider adding geographic coordinates for mapping
4. Follow the same file naming convention

For questions about data preparation, see the main README.md file.
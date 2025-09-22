# Population Structure Clustering Workflow

This repository provides a comprehensive tutorial and workflow for performing population structure clustering analysis using multiple complementary tools. This guide walks you through the entire process, from data preparation to creating publication-quality visualizations.

**Note:** This project is a work in progress, and currently contains only starter scripts. More detailed scripts will be added soon.

## Workflow
1. Perform global ancestry inference using either ***ADMIXTURE*** or ***STRUCTURE***, or both.
2. Run ***Clumppling*** to align the clustering results from step 1 (with static figures generated).
3. Use ***Kalignedoscope*** to interactively visualize the aligned clustering results from step 2.

## Table of Contents

* [Data Preparation](#input-data-preparation)
* [***ADMIXTURE*** Analysis](#admixture-analysis)
* [***STRUCTURE*** Analysis](#structure-analysis)
* [***Clumppling*** Analysis](#clumppling-analysis)
* [***KAlignedoscope*** Visualization](#kalignedoscope-visualization)


## Software Requirements

Depending on your analysis needs, ensure you have the appropriate software(s) installed:

- [*only if data conversion is needed*] PLINK: see [PLINK 2.0](https://www.cog-genomics.org/plink/2.0) and [PLINK 1.9](https://www.cog-genomics.org/plink2)
- ADMIXTURE (v1.3.0): see [https://github.com/NovembreLab/admixture](https://github.com/NovembreLab/admixture)
- STRUCTURE (v2.3.4): see [https://web.stanford.edu/group/pritchardlab/structure.html](https://web.stanford.edu/group/pritchardlab/structure.html)
- Clumppling (v2.0), which requires Python (v3.8-v3.12) with designated packages: see [https://github.com/PopGenClustering/Clumppling](https://github.com/PopGenClustering/Clumppling)
- Kalignedoscope (v1.0), which requires Python 3


## Input Data Preparation

**Note: We skip any QC or pruning.**

This workflow assumes genetic data in PLINK binary format, which is compatible with **ADMIXTURE**:
- `.bed` file: Binary genotype data
- `.bim` file: Variant information (chromosome, position, alleles)
- `.fam` file: Sample information (family ID, individual ID, population labels)

If data is in VCF format, run following code snippet to convert it to PLINK format (using PLINK 2.0).
```bash
plink2 --vcf DATA.vcf.gz \
  --set-all-var-ids '@:#:$ref:$alt' \
  --make-bed \
  --out DATA_admixture_input
```
*If your data is seperated by chromosomes, merge them before proceed:
```bash
# create a merge list file
for chr in {2..22}; do
  echo "DATA_chr${chr}"
done > merge_list.txt
# merge data (using PLINK 1.9)
plink --bfile DATA_chr1 --merge-list merge_list.txt --make-bed --out DATA_allchr
```

If you will be running **STRUCTURE**, convert your data into STRUCTURE-compatible format:
```bash
plink --bfile DATA_admixture_input --recode12 --out DATA_structure_input

awk '{
    id=$2; pop=1;
    printf "%s %s", id, pop;
    for(i=7;i<=NF;i++){ 
        if($i ~ /^[012]$/){ printf " %s", $i } 
        else { printf " 0" }  # replace anything unexpected with missing
    }
    printf "\n"
}' DATA_structure_input.ped > DATA_structure_input.str
```

## ADMIXTURE Analysis
Define `ADMIXTURE_OUTPUT_DIR`.

For number of clusters *K* from 2 to 8, each with 10 runs:
```bash
for K in {2..8}; do
    for i in {1..10}; do 
        admixture -s $i -j4 DATA_admixture_input.bed $K 
        # rename outputs
        mv DATA_admixture_input.${K}.Q ${ADMIXTURE_OUTPUT_DIR}/K${K}_run${i}.Q
        mv DATA_admixture_input.${K}.P ${ADMIXTURE_OUTPUT_DIR}/K${K}_run${i}.P
    done
done
```

## STRUCTURE Analysis
Define `STRUCTURE_OUTPUT_DIR`.

First, create the ``mainparams`` file required by STRUCTURE (and suppose we use the default ``extraparams`` file):
```
numinds=$(wc -l < DATA_admixture_input.fam)
numloci=$(wc -l < DATA_admixture_input.bim)
# Create mainparams file
cat > mainparams <<EOF
#define MAXPOPS    10
#define BURNIN     10000
#define NUMREPS    20000

#define INFILE     in_file
#define OUTFILE    out_file

#define NUMINDS    ${numinds}
#define NUMLOCI    ${numloci}

#define PLOIDY     2
#define MISSING    0

#define ONEROWPERIND    1
#define LABEL     1
#define POPDATA   1
#define POPFLAG   0
#define LOCDATA   0
#define PHENOTYPE 0
#define EXTRACOLS 0

#define MARKERNAMES      0  
EOF
```

Then run the program, similarly for number of clusters *K* from 2 to 8, each with 10 runs:
```
for K in {2..8}; do
    for i in {1..10}; do
        out_file=${STRUCTURE_OUTPUT_DIR}/K${K}_run${i}
        $software_dir/structure \
            -i DATA_structure_input.str \
            -m mainparams \
            -e extraparams \
            -K $K \
            -D $i \
            -o $out_file > ${STRUCTURE_OUTPUT_DIR}/log_K${K}_run${i}.txt
    done
done
```

## Clumppling Analysis

### Quick install
```bash
conda create -n clumppling-env python=3.12
conda activate clumppling-env
pip install clumppling
```
To check installation success, run ``python -m clumppling -h`` to see the helper message.

### Prepare label file (optional)
```bash
# prepare a file of population labels separatelym if needed (using 1KG data as example)
fam_file=DATA_admixture_input.fam
panel_file=integrated_call_samples_v3.20130502.ALL.panel
POP_LABEL_FILE=${CLUMPPLING_INPUT_DIR}/population_labels.txt
awk 'NR==FNR{pop[$1]=$2; next} {print pop[$2]}' "$panel_file" "$fam_file" > POP_LABEL_FILE
```

### With ADMIXTURE output
Define `CLUMPPLING_INPUT_DIR` and `CLUMPPLING_OUTPUT_DIR`, then move files to the input directory:
```bash
for K in {2..8}; do
    # Loop over all run indices i (assuming they are numbered like run1.Q, run2.Q, etc.)
    for file in ${ADMIXTURE_OUTPUT_DIR}/K${K}_run*.Q; do 
        if [ -f "$file" ]; then
            echo "Copying $file -> ${CLUMPPLING_INPUT_DIR}
            cp "$file" ${CLUMPPLING_INPUT_DIR}/
        fi
    done
done
```
Run the program
```bash
python -m clumppling -i ${CLUMPPLING_INPUT_DIR} -o ${CLUMPPLING_OUTPUT_DIR} \
-f admixture --extension .Q --ind_labels ${POP_LABEL_FILE}
```

### With STRUCTURE output
Define `CLUMPPLING_OUTPUT_DIR`, and set
```bash
CLUMPPLING_INPUT_DIR=${STRUCTURE_OUTPUT_DIR}
```
```bash
python -m clumppling -i ${CLUMPPLING_INPUT_DIR} -o ${CLUMPPLING_OUTPUT_DIR} \
-f structure --extension _f --ind_labels ${POP_LABEL_FILE}
```

## KAlignedoScope Visualization
### Quick install
```bash
pip install kalignedoscope
```
To check installation success, run ``python -m kalignedoscope -h`` to see the helper message.

### Visualize Clumppling results
```bash
python -m kalignedoscope ...
```

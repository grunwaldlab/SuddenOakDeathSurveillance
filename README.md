# Phylogeographic Monitoring of Sudden Oak Death Pathogen using Nextstrain

This project implements a Snakemake pipeline for genomic biosurveillance of *Phytophthora ramorum*, the oomycete pathogen responsible for sudden oak death (SOD). The pipeline analyzes mitochondrial genome sequences to create interactive phylogenetic visualizations that monitor the emergence of new variants and clonal lineages of the SOD pathogen.

This the repository for the source code used to create the visualization which is hosted at ()[https://nextstrain.org/community/grunwaldlab/nextstrainoomy].

## Requirements

- [Nextstrain CLI](https://docs.nextstrain.org/en/latest/install.html)


## Quick Start

### Building the analysis

To run the complete phylogenetic analysis pipeline, download/clone this repository, change into the resulting directory and run:

```bash
nextstrain build .
```

This executes the Snakemake workflow and generates the final visualization file.

### Viewing results

To view the interactive phylogenetic visualization:

```bash
nextstrain view auspice/
```

Then open your browser to the displayed URL.

## Dataset

The repository includes a ~700 mitochondrial genomes of *P. ramorum* sampled between 1995 and 2019 from around the world.
Only sequences associated with a known date and location were included in the analysis.

!()[results/genome_abundance_plot.png]

## Input Data

- `data/ramorum_mito_genomes.fasta` - Assembled mitochondrial genome sequences
- `data/formatted_metadata.tsv` - Sample metadata (location, date, lineage, host species, etc.)
- `data/martin2007_pr-102_v3.1_mito_ref.fasta` - Reference mitochondrial genome for alignment
- `data/MT_DQ832718.1.gb` - Gene reference for translation and annotation
- `data/dropped_strains.txt` - Sequences to exclude from analysis
- `data/colors.tsv` - Color scheme for lineages and geographic regions
- `data/lat_longs.tsv` - Geographic coordinates for mapping
- `data/auspice_config.json` - Auspice display configuration

## Output

The main output is `auspice/SuddenOakDeathSurveillance.json`, which contains all the data needed for visualization by `auspice`.
Intermediate results in `results/` directory include filtered sequences, alignments, trees, and various node data files.

## Data Updates

New mitochondrial genome data can be added by:
1. Adding sequences to the input FASTA file
2. Updating metadata with sample information
3. Re-running the pipeline with `nextstrain build .`

The visualization automatically updates when new data is processed through the pipeline.

## Authors

- Zachary S. L. Foster¹
- Nicholas C. Cauldron²
- Caroline M. Press¹
- Valerie J. Fieland²
- Thomas Jung³
- Jared LeBoldus²
- Jeffrey H. Chang²
- Niklaus J. Grünwald¹

¹ Horticultural Crops Research Laboratory, USDA ARS, Corvallis, OR, USA  
² Department of Botany and Plant Pathology, Oregon State University, Corvallis, OR, USA  
³ Mendel University, Czech Republic

## Funding

This project was supported by USDA-ARS CRIS Projects 2072-22000-041-00-D and 2072-22000-043-00-D, the USDA-ARS Floriculture Nursery Initiative, and the Phytophthora Diagnostics grant from USFS.

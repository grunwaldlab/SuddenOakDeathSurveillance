# Running augur on oomy

I began testing the augur install on oomy by following the
[zika] (https://docs.nextstrain.org/en/latest/tutorials/zika.html)
tutorial. In the "Align the Sequences" section I ran into an error regarding
permission on creating new files. In short, augur align calls mafft which
attempts to create temporary files at `$TMPDIR`. Normally, this runs without
issue, however, since oomy is set up on the CGRB infrastructure, $TMPDIR is
set to the "scratch" workspace /data/. Since /data/ has restricted permissions
on oomy, I had to reset $TMPDIR to /tmp using:

`export TMPDIR=/tmp/`

This could be addressed on the oomy system as a whole, however, that would
interfere with any CGRB jobs submitted to the job queue when logged into oomy.
For the time being, the value of TMPDIR will need to be changed prior to 
command execution.

*Update*: This is now fixed. TMPDIR is automatically set upon conda activation.


## Observations
### Fasta file input
Each entry is a different lineage. Can't have multi-scaffold genomes?

## indexing
Just counts number of nucleotides in fasta file.

## Filtering
Removes strains found in "config/dropped_strains.txt".
Resamples remaining strains? <- Based on "virus" column of metadata.tsv 

## Align
Aligning takes a reference sequence found in "config/zika_outgroup.gb"
What formats are allowed here?
Use:

`--reference-name NAME`

if reference sequence is in the fasta file. According to augur translate, the
reference sequence should be of the form:

  --reference-sequence REFERENCE_SEQUENCE
                        GenBank or GFF file containing the annotation


# Test data from Alex
The concatonated fasta file `agronurserymlsa.concat.bv1.fasta` contained
pre-aligned amino acid sequences. It is unclear at this point if this is a
valid input into the Nextrain/augur pipeline. For a proof of concept, I first
converted the aligned amino acid sequences into a nucletoide fasta file without
any alignment. This was done with the `revert.py` script I wrote.

## Indexing
Ran:

`augur index --sequences data/sequences.fasta --output results/sequence_index.tsv`

with no issues.

## Filtering
Next tried to filter the data using:

`augur filter   --sequences data/sequences.fasta   --sequence-index results/sequence_index.tsv   --metadata data/metadata.tsv --output results/filtered.fasta   --group-by country year month`

Errors encountered:
`Metadata file data/metadata.tsv does not contain "name" or "strain"`

The column was Strain not strain...lol

It filtered out some strains with no metadata:

No meta data for LMG_305, excluding from all further analysis.
No meta data for G_8.3, excluding from all further analysis.
No meta data for LMG_215, excluding from all further analysis.
No meta data for LMG_232, excluding from all further analysis.
No meta data for LMG_267, excluding from all further analysis.
No meta data for LMG_292, excluding from all further analysis.
No meta data for ATCC_15955, excluding from all further analysis.
No meta data for M56_/79, excluding from all further analysis.
No meta data for 06-478_st, excluding from all further analysis.
No meta data for NCPPB_2655, excluding from all further analysis.
No meta data for NCPPB_2657, excluding from all further analysis.

### Aligning
The augur align command takes as input a reference sequence or a reference
name. If a reference sequence is given, it should be the path to a genbank
data file (.gb). If a reference name is given, it is assumed that the sequence
is already contained within the fasta file. I chose *C58* as the reference as
this was the first entry in filtered.fasta. Also had to export /tmp/ again...

Ran:

`augur align --sequences results/filtered.fasta --reference-name C58 --output results/aligned.fasta --fill-gaps --nthreads 8`

Appears to have finished even though I got logged out.

## Phylogeny
Ran:
`augur tree --alignment results/aligned.fasta --output results/tree_raw.nwk`


## Time resolved tree
Ran:
```
augur refine \
  --tree results/tree_raw.nwk \
  --alignment results/aligned.fasta \
  --metadata data/metadata.tsv \
  --output-tree results/tree.nwk \
  --output-node-data results/branch_lengths.json \
  --timetree \
  --coalescent opt \
  --date-confidence \
  --date-inference marginal \
  --clock-filter-iqd 4
```

got: treetime.MissingDataError: ERROR: ALMOST NO VALID DATE CONSTRAINTS

# Running test data from Alex (Part 2: VCF input)
Decided to restart with the new VCF data and reference fasta File. All work is
being done in the `/www/grunwaldlab_nextstrain/chang_test_vcf` directory on
oomy. Data files are stored in ./data/

`VCF : G4_jointcalls.snpsonly.filtereddefaultQD10.pass.forandrew.vcf`
`Fasta : REF.fna`
`metadata : bv1list.table.plasmid.txt`

I modified the metadata file to have '?' in fields with missing data. As
defined in the augur traits help guide.

## augur index
Skipped, I think this is only ever relevant for input Fasta files and filtering
will generate an index file on the file automatically.

## augur filter
Applied minimal filtering rules which removed:

```
No meta data for LMG_305, excluding from all further analysis.
No meta data for LMG_215, excluding from all further analysis.
No meta data for LMG_267, excluding from all further analysis.
No meta data for 16-1607-1A, excluding from all further analysis.
```

and produced `results/filtered.vcf`

## augur align
Not needed since input is vcf data

## augur tree
Ran into error, appears only a single entry can be in the fasta file.



# Restart

I stripped the second scaffold from the vcf file using this while in data/:

`vcftools --vcf data.vcf --chr LT009758.1 --recode --recode-INFO-all --out data_LT009758.1.vcf`

I also manually deleted the second fasta entry in the reference fasta.

## New Data files
New data files (all found in Snakemake file):

`VCF : data/data_LT009758.1.vcf.recode.vcf`
`Fasta : data_LT009758.1.fna`
`metadata : data/data.tsv`


## augur filter

Ran filtering using:

`snakemake filter --cores 4`

Applied minimal filtering rules which removed:

```
No meta data for LMG_305, excluding from all further analysis.
No meta data for LMG_215, excluding from all further analysis.
No meta data for LMG_267, excluding from all further analysis.
No meta data for 16-1607-1A, excluding from all further analysis.
```

and produced `results/filtered.vcf`

## augur tree

Made tree using:

`snakemake tree --cores 4`

This time it appeared to work fine. The tree is in:

`results/tree_raw.nwk`

## augur refine

Refined tree using:

`snakemake refine --cores 4`

Attempting to determine dates kept giving an error:

`treetime.MissingDataError: ERROR: ALMOST NO VALID DATE CONSTRAINTS`

But turning off the timetree option allowed me to proceed.

## augur traits
Got traits from tree using:

`snakemake traits --cores 4`

predicting these traits:

`host plasmid_classification`

## augur ancestral

Predicted ancestral state using:

`snakemake ancestral --cores 4`

## augur translate

Predicted protein sequences using:

`snakemake translate --cores 4`

--failed...

# augur export

success!

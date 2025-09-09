rule all:
    input:
        auspice_json = "auspice/nextstrainoomy.json"

# Set input filenames
seq_file = "data/ramorum_mito_genomes.fasta"
meta_file = "data/formatted_metadata.tsv"
ref_file = "data/martin2007_pr-102_v3.1_mito_ref.fasta"
generef_file = "data/MT_DQ832718.1.gb"
dropped_strains = "data/dropped_strains.txt"
colors_file = "data/colors.tsv",
geo_info_file = "data/lat_longs.tsv",
config_file = "data/auspice_config.json"


rule filter:
    message:
        """
        Applying minimal filtering rules.
        """
    input:
        seq = seq_file,
        meta = meta_file,
        exclude = dropped_strains
    output:
        "results/filtered.fasta"
    shell:
        """
        augur filter \
            --sequences {input.seq} \
            --metadata {input.meta} \
            --exclude {input.exclude} \
            --output-sequences {output}
        """

rule align:
    message:
        """
        Aligning sequences to {input.ref}
          - filling gaps with N
        """
    input:
        sequences = rules.filter.output,
        ref = ref_file
    output:
        alignment = "results/aligned.fasta"
    shell:
        """
        augur align \
            --sequences {input.sequences} \
            --reference-sequence {input.ref} \
            --output {output.alignment} \
            --nthreads 16 \
            --fill-gaps
        """


rule tree:
    message: "Building tree"
    input:
        aln = rules.align.output,
    output:
        "results/tree_raw.nwk"
    shell:
        """
        augur tree \
            --alignment {input.aln} \
            --output {output}
        """


rule refine:
    message:
        """
        Refining tree
          - estimate timetree
          - use {params.coal} coalescent timescale
        """
    input:
        tree = rules.tree.output,
        aln = rules.align.output,
        metadata = meta_file
    output:
        tree = "results/tree.nwk",
        node_data = "results/branch_lengths.json"
    params:
        root = "oldest",
        coal = "opt"
    shell:
        """
        augur refine \
            --tree {input.tree} \
            --alignment {input.aln} \
            --metadata {input.metadata} \
            --timetree \
            --coalescent {params.coal} \
            --root PR-18-130 \
            --output-tree {output.tree} \
            --output-node-data {output.node_data}
        """

rule ancestral:
    message: "Reconstructing ancestral sequences and mutations"
    input:
        tree = rules.refine.output.tree,
        aln = rules.align.output,
    output:
        nt_data = "results/nt_muts.json",
    params:
        inference = "joint"
    shell:
        """
        augur ancestral \
            --tree {input.tree} \
            --alignment {input.aln} \
            --inference {params.inference} \
            --output-node-data {output.nt_data} \
        """

rule translate:
    message: "Translating amino acid sequences"
    input:
        tree = rules.refine.output.tree,
        node_data = rules.ancestral.output.nt_data,
        gene_ref = generef_file,
    output:
        aa_data = "results/aa_muts.json",
    shell:
        """
        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.gene_ref} \
            --output-node-data {output.aa_data} \
        """

rule traits:
    message: "Inferring ancestral traits for {params.traits!s}"
    input:
        tree = rules.refine.output.tree,
        meta = meta_file
    output:
        "results/traits.json",
    params:
        traits_alt = "lineage country state date",
        traits = "date"
    shell:
        """
        augur traits \
            --tree {input.tree} \
            --metadata {input.meta} \
            --columns {params.traits} \
            --confidence \
            --output-node-data {output}
        """

rule export:
    message: "Exporting data files for for auspice"
    input:
        tree = rules.refine.output.tree,
        metadata = meta_file,
        branch_lengths = rules.refine.output.node_data,
        traits = rules.traits.output,
        nt_muts = rules.ancestral.output.nt_data,
        aa_muts = rules.translate.output.aa_data,
        color_defs = colors_file,
        config = config_file,
        geo_info = geo_info_file
    output:
        auspice_json = rules.all.input.auspice_json
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --node-data {input.branch_lengths} {input.traits} {input.nt_muts} {input.aa_muts} \
            --colors {input.color_defs} \
            --lat-longs {input.geo_info} \
            --auspice-config {input.config} \
            --output {output.auspice_json}
        """

rule clean:
    message: "Removing directories: {params}"
    params:
        "results ",
        "auspice"
    shell:
        "rm -rfv {params}"

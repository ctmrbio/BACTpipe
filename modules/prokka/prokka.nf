nextflow.enable.dsl = 2

process PROKKA {
    tag { pair_id }
    publishDir "${params.output_dir}/prokka", mode: 'copy'

    input:
    path(profile_file)
    tuple val(pair_id), path(contigs_file)

    output:
    path("${pair_id}_prokka")

    script:

    def bacterial_profile = file(profile_file.resolveSymLink()).getText().split("\t")
    def stain = bacterial_profile[0]
    def genus = bacterial_profile[1]
    def species = bacterial_profile[2]

    prokka_reference_argument = ""
    if( params.prokka_reference ) {
        prokka_reference_argument = "--proteins ${params.prokka_reference}"
    }

    prokka_gramstain_argument = ""

    if( params.prokka_signal_peptides ) {
        if( stain == "pos" ) {
            prokka_gramstain_argument = "--gram pos"
        } else if( stain == "neg" ) {
            prokka_gramstain_argument = "--gram neg"
        } else {
            prokka_gramstain_argument = ""
        }
    } else {
        prokka_gramstain_argument = ""
    }

    prokka_genus_argument = ""
    prokka_species_argument = ""

    if( genus != "Multiple" ) {
        prokka_genus_argument = "--genus ${genus}"
        prokka_species_argument = "--species ${species}"
    } else {
        prokka_genus_argument = "--genus Multiple_taxa"
    }

    """
    prokka \
        --cpus ${task.cpus} \
        --force \
        --evalue ${params.prokka_evalue} \
        --kingdom ${params.prokka_kingdom} \
        --locustag ${pair_id} \
        --outdir ${pair_id}_prokka \
        --prefix ${pair_id} \
        --strain ${pair_id} \
        ${prokka_reference_argument} \
        ${prokka_gramstain_argument} \
        ${prokka_genus_argument} \
        ${prokka_species_argument} \
        ${contigs_file}
    """

    stub:
    """
    mkdir ${pair_id}_prokka
    """

}


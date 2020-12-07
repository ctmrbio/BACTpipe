
process PROKKA {
    tag { pair_id }
    publishDir "${params.output_dir}/prokka", mode: 'copy'

    input:
    tuple val(pair_id), path("${pair_id}.contigs.fa")
    sketch_string

    output:
    path("${pair_id}_prokka")

    script:

    prokka_reference_argument = ""
    if (params.prokka_reference) {
        prokka_reference_argument = "--proteins ${params.prokka_reference}"
    }

    stain = sketch_string.split(",")[0]
    genus = sketch_string.split(",")[1]
    species = sketch_string.split(",")[2]

    prokka_gramstain_argument = ""
    prokka_genus_argument = ""
    prokka_species_argument = ""

    if (stain == "pos") {
        prokka_gramstain_argument = "--gram pos"
    } else if (stain == "neg") {
        prokka_gramstain_argument = "--gram neg"
    } else {
        prokka_gramstain_argument = ""
    }


    if (genus != "Multiple") {
        prokka_genus_argument = "--genus " + genus
        prokka_species_argument = "--species " + species
    } else {
        prokka_genus_argument = "--genus Multiple_taxa"
    }


    if (stain == "Not_in_list") {
        print("Genus not found in referencelist and remains unstained!")
    } else if (stain == "Contaminated") {
        print("Sample contains more than one genus!")
    }

    """
    prokka \
        --force \
        --evalue ${params.prokka_evalue} \
        --kingdom ${params.prokka_kingdom} \
        --locustag ${pair_id} \
        --outdir ${pair_id}_prokka \
        --prefix ${pair_id} \
        --strain ${pair_id} \
        --compliant \
        ${prokka_reference_argument} \
        ${prokka_gramstain_argument} \
        ${prokka_genus_argument} \
        ${prokka_species_argument} \
        ${pair_id}.contigs.fa
    """
}

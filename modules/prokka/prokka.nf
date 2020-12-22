nextflow.enable.dsl = 2

process PROKKA {
    tag { pair_id }
    publishDir "${params.output_dir}/prokka", mode: 'copy'

    input:
    tuple val(pair_id), path(contigs_file)
    tuple val(stain), val(genus), val(species)

    output:
    path("${pair_id}_prokka")

    script:

    prokka_reference_argument = ""
    if( params.prokka_reference ) {
        prokka_reference_argument = "--proteins ${params.prokka_reference}"
    }

    prokka_gramstain_argument = ""

    if( params.prokka_gram && stain == "pos" ) {
        prokka_gramstain_argument = "--gram pos"
    } else if( stain == "neg" ) {
        prokka_gramstain_argument = "--gram neg"
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
        --force \
        --cpus ${task.cpus} \
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
        --compliant \
        ${contigs_file}
    """
}


// Prokka module can be tested by invoking the following statement from the project base directory.
// nextflow run modules/prokka/prokka.nf -entry test
workflow test {

    include { SCREEN_FOR_CONTAMINANTS } from "../screen_for_contaminants/screen_for_contaminants.nf"
    SCREEN_FOR_CONTAMINANTS(["SRR1544630", "$baseDir/test_data/SRR1544630.contigs.fa"])

    params.prokka_evalue = "1e-09"
    params.prokka_kingdom = 'Bacteria'

    contamination_profile_ch = SCREEN_FOR_CONTAMINANTS.out[0]
            .splitCsv(sep: '\t', strip: true)
            .map { row ->
                tuple(
                        row[0], //stain
                        row[1], //genus
                        row[2], //species
                )
            }

    PROKKA(["SRR1544630", "$baseDir/test_data/SRR1544630.contigs.fa"],
            contamination_profile_ch
    )

}

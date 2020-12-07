nextflow.enable.dsl = 2

process PROKKA {
    tag { pair_id }
    publishDir "${params.output_dir}/prokka", mode: 'copy'

    input:
    tuple val(pair_id), path(contigs_file)
    val(stain_genus_species)

    output:
    path("${pair_id}_prokka")

    script:

    prokka_reference_argument = ""

    sketch_string = stain_genus_species.toString().split("\\t")

    stain = sketch_string[0].strip()
    genus = sketch_string[1].strip()
    species = sketch_string[2].strip()

    prokka_gramstain_argument = ""

    if (stain == "pos") {
        prokka_gramstain_argument = "--gram pos"
    } else if (stain == "neg") {
        prokka_gramstain_argument = "--gram neg"
    } else {
        prokka_gramstain_argument = ""
    }

    prokka_genus_argument = ""
    prokka_species_argument = ""

    if (genus != "Multiple") {
        prokka_genus_argument = "--genus ${genus}"
        prokka_species_argument = "--species ${species}"
    } else {
        prokka_genus_argument = "--genus Multiple_taxa"
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
        ${prokka_reference_argument} \
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

    PROKKA(["SRR1544630", "$baseDir/test_data/SRR1544630.contigs.fa"],
            SCREEN_FOR_CONTAMINANTS.out[0]
    )

}

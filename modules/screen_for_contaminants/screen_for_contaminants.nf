nextflow.enable.dsl = 2

process SCREEN_FOR_CONTAMINANTS {
    tag { pair_id }
    publishDir "${params.output_dir}/sendsketch", mode: 'copy', pattern: "${pair_id}.sendsketch.txt"
    errorStrategy "retry"
    maxRetries 3
    
    input:
    tuple val(pair_id), path(contigs_file)

    output:
    path "${pair_id}_stain_genus_species.tsv"
    tuple val(pair_id), path("${contigs_file}")
    path "${pair_id}.sendsketch.txt"

    script:
    """
    sendsketch.sh \
        in=${contigs_file} \
        samplerate=0.1 \
        out=${pair_id}.sendsketch.txt

    # This process yields the main stdout for prokka
    sendsketch_to_prokka.py \
        --sketch ${pair_id}.sendsketch.txt \
        --stain $projectDir/resources/gram_stain.txt \
        --profile ${pair_id}_stain_genus_species.tsv

    """

    stub:
    """
    touch ${pair_id}_stain_genus_species.tsv
    touch ${pair_id}_contig.fa
    touch ${pair_id}.sendsketch.txt
    """
}

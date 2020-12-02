
process SCREEN_FOR_CONTAMINANTS {
    tag { pair_id }
    publishDir "${params.output_dir}/sendsketch", mode: 'copy'

    input:
    tuple val(pair_id), path("${pair_id}.contigs.fa")

    output:
    path("${pair_id}.sendsketch.txt")
    stdout

    script:
    """
    sendsketch.sh \
        in=${pair_id}.contigs.fa \
        samplerate=0.1 \
        out=${pair_id}.sendsketch.txt

    sendsketch_to_prokka.py \
        ${pair_id}.sendsketch.txt \
        "$projectDir/resources/gram_stain.txt"
    """
}

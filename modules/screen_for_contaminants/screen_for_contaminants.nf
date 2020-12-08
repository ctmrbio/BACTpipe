nextflow.enable.dsl = 2

process SCREEN_FOR_CONTAMINANTS {
    tag { pair_id }
    publishDir "${params.output_dir}/sendsketch", mode: 'copy'

    input:
    tuple val(pair_id), path(contigs_file)

    output:
    stdout
    path "${pair_id}.sendsketch.txt"

    script:
    """
    sendsketch.sh \
        in=${contigs_file} \
        samplerate=0.1 \
        out=${pair_id}.sendsketch.txt

    # This process yields the main stdout for prokka
    sendsketch_to_prokka.py \
        ${pair_id}.sendsketch.txt \
        $projectDir/resources/gram_stain.txt

    """
}

workflow test {


    input = ["SRR1544630", "$baseDir/test_data/SRR1544630.contigs.fa"]


    SCREEN_FOR_CONTAMINANTS(input)
}

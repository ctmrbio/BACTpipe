
process FASTP {
    tag { pair_id }
    publishDir "${params.output_dir}/fastp", mode: 'copy'

    input:
    tuple val(pair_id), path(reads)

    output:
    tuple val(pair_id), path("${pair_id}_{1,2}.fastp.fq.gz"), emit: shovill_input
    path "${pair_id}.json", emit: fastp_reports

    script:
    """
    fastp \
        --in1 ${reads[0]} \
        --in2 ${reads[1]} \
        --out1 ${pair_id}_1.fastp.fq.gz \
        --out2 ${pair_id}_2.fastp.fq.gz \
        --json ${pair_id}.json \
        --html ${pair_id}.html \
        --thread ${task.cpus}
    """

    stub:
    """
    touch ${pair_id}_1.fastp.fq.gz
    touch ${pair_id}_2.fastp.fq.gz
    
    touch ${pair_id}.json
    """
}

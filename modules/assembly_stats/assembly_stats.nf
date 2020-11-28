
process ASSEMBLY_STATS {
    tag { pair_id }
    publishDir "${params.output_dir}/shovill", mode: 'copy'

    input:
    tuple val(pair_id), file("${pair_id}.contigs.fa")

    output:
    file("${pair_id}.assembly_stats.txt")

    """
    statswrapper.sh \
        in=${pair_id}.contigs.fa \
        > ${pair_id}.assembly_stats.txt        
    """
}

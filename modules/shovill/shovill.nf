
process SHOVILL {
    tag { pair_id }
    publishDir "${params.output_dir}/shovill", mode: 'copy'

    input:
    tuple pair_id, path(reads)

    output:
    tuple pair_id, path("${pair_id}.contigs.fa")
    path("${pair_id}_shovill/*.{fasta,fastg,log,fa,gfa,changes,hist,tab}")

    """
    shovill \
         --depth ${params.shovill_depth} \
         --kmers ${params.shovill_kmers} \
         --minlen ${params.shovill_minlen} \
         --R1 ${reads[0]} \
         --R2 ${reads[1]} \
         --outdir ${pair_id}_shovill
    cp ${pair_id}_shovill/contigs.fa ${pair_id}.contigs.fa
    """
}

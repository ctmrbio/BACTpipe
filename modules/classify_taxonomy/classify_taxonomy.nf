nextflow.enable.dsl = 2

process CLASSIFY_TAXONOMY {
    tag { pair_id }
    publishDir "${params.output_dir}/kraken2", mode: 'copy', pattern: "${pair_id}.kreport"
    
    input:
    tuple val(pair_id), path(reads)

    output:
    path "${pair_id}.kreport"
    path "${pair_id}.taxonomy.txt", emit: classification

    script:
    """
	kraken2 \
	    --quick \
		--db ${params.kraken2_db} \
		--threads ${task.cpus} \
		--confidence ${params.kraken2_confidence} \
		--output - \
		--report ${pair_id}.kreport \
		--use-names \
		--paired \
		${reads[0]} ${reads[1]}

	awk '{if (\$1 > ${params.kraken2_min_proportion} && \$4 == "S") print \$0}' ${pair_id}.kreport > ${pair_id}.taxonomy.txt
    """


    stub:
    """
    touch ${pair_id}.kreport
    touch ${pair_id}.taxonomy.txt
    """
}

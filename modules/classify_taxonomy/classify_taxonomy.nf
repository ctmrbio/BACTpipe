nextflow.enable.dsl = 2

process CLASSIFY_TAXONOMY {
    tag { pair_id }
    publishDir "${params.output_dir}/kraken2", mode: 'copy'
    
    input:
    tuple val(pair_id), path(reads)

    output:
    path "${pair_id}.kreport"
    path "${pair_id}.classification.txt", emit: classification

    script:
	if ( params.kraken2_db ) {
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
		
		classify_kreport.py \
			--kreport ${pair_id}.kreport \
			--min-proportion ${params.kraken2_min_proportion} \
			--gramstains ${projectDir}/resources/gram_stain.txt \
			> ${pair_id}.classification.txt
		"""
	}
    else {
		log.warning "No Kraken2 database specified, sample will not be classified."
		"""
    	touch ${pair_id}.kreport
        echo "Unknown\tunknown\tUnknown" > ${pair_id}.classification.txt
    	"""
	}

    stub:
    """
    touch ${pair_id}.kreport
    touch ${pair_id}.classificaton.txt
    """
}

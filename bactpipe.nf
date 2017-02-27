#!/usr/bin/env nextflow

//create in put_channel
adapters_file = file(params.adapters)


//Creates the `read_pairs` channel that emits for each read-pair a tuple containing
//three elements: the pair ID, the first read-pair file and the second read-pair file

Channel
    .fromFilePairs( params.reads )
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .set { read_pairs }

//process 1: Adapter and quality trimming

process bbduk {
        tag {pair_id}
        publishDir 'bbduk'

        input:
        set pair_id, file(reads) from read_pairs
        file adapters_file

        output:
        set pair_id, file("*.bbduk.fastq") into fastqc_input, spades_input
        file "${pair_id}.stats.txt"
       
		
        script:
	"""
        bbduk.sh \
             in1=${reads[0]} \
             in2=${reads[1]} \
             ref=${adapters_file} \
	     out1=${reads[0].baseName}.bbduk.fastq \
             out2=${reads[1].baseName}.bbduk.fastq \
             stats=${pair_id}.stats.txt \
             threads=${task.cpus} \
             minlen=30 \
             qtrim=rl \
             trimq=10 \
             ktrim=r \
             k=30 \
             mink=11 \
             hdist=1 \
             trimbyoverlap \
             trimpairsevenly \
        """

}
 
//STEP 2 - FastQC
 
process fastqc {
	
		tag "$name"
		publishDir 'fastqc_results'
                
		
		input:
		set val(name), file(clean_reads) from fastqc_input
		
		output:
		file "*_fastqc.{zip,html}" into fastqc_output
		
		
		"""
                 
		fastqc --quiet ${clean_reads} \
                       --threads ${task.cpus} \
		
		"""

}

//Step 3 SPAdes
process spades {
        tag {pair_id}
        publishDir "spades/${pair_id}"

        input:
        set pair_id, file(reads) from spades_input
        
        output:
        set pair_id, file("spades_output/scaffolds.fasta") into spades_result
     	file("spades_output/*.{fasta,fastg}") 
        
        
        """
        spades.py \
        -k 21,33,55,77,99,127 \
        --careful \
        --threads ${task.cpus} \
        --pe1-1 ${reads[0]} \
        --pe1-2 ${reads[1]} \
        -o spades_output \
        """
}

//filtering scaffolds

process filter_scaffolds {
            
        tag {pair_id}
        publishDir "filtered_scaffolds/${pair_id}"
        
        input:
        set pair_id, file(scaffolds) from spades_result
        
        output:
        set pair_id, file("${pair_id}_covfiltered.fasta") into filtered_channel
        
        
        """
        FilterAssembly.pl \
            $scaffold \  
            ${pair_id} \
        """
}

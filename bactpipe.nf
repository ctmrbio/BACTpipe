#!/usr/bin/env nextflow

//create input channel

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
        publishDir "${params.output_dir}/bbduk", mode: 'copy'
        
        input:
        set pair_id, file(reads) from read_pairs
        file adapters_file

        output:
        set pair_id, file("*.bbduk.fastq") into fastqc_input, shovill
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
		publishDir "${params.output_dir}/fastqc", mode: 'copy'
                
		
		input:
		set val(name), file(clean_reads) from fastqc_input
		
		output:
		file("*_fastqc.{zip,html}") into fastqc_output
		
		
		"""
                 
		fastqc --quiet ${clean_reads} \
                       --threads ${task.cpus} \
		
		"""

}

//Step 3 shovill
process shovill {
        tag {pair_id}
        publishDir "${params.output_dir}/shovill", mode: 'copy'

        input:
        set pair_id, file(reads) from shovill
        
        output:
        set pair_id, file("${pair_id}.contigs.fa") into stats_ch, prokka_channel
     	file("${pair_id}_shovill/*.{fasta,fastg,log,fa,gfa,changes,hist,tab}") 
        
        
        """
        shovill \
             --depth 100 \
             --kmers 21,33,55,77,99,127 \
             --minlen 500 \
             --R1 ${reads[0]} \
             --R2 ${reads[1]} \
             --outdir ${pair_id}_shovill 

        cp ${pair_id}_shovill/contigs.fa ${pair_id}.contigs.fa
        """
}


//Assembly stats using statswrapper.sh

process stats {

       tag "$name"
       publishDir "${params.output_dir}/assembly_stats", mode: 'copy'

       input:
       set val(name), file(contigs) from stats_ch

       output:
       file("${name}.stats.txt") into statistics_ch

       """
       statswrapper.sh in=$contigs >> ${name}.stats.txt

       """

}

// Annotation with prokka
  
process prokka {

        tag {sample_id}
        publishDir "${params.output_dir}/prokka", mode: 'copy'

        input:
        set sample_id, file(renamed_contigs) from prokka_channel


        output:
        set sample_id, file("${sample_id}_prokka")

        """
        prokka \
        --outdir ${sample_id}_prokka --force \
        --prefix ${sample_id} --addgenes --locustag ${sample_id} \
        --strain ${sample_id} \
        --kingdom Bacteria \
        --evalue 1e-12 \
        $renamed_contigs

        """
}

workflow.onComplete { 
	println ( workflow.success ? "Done!" : "Oops .. something went wrong" )
}

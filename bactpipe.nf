#!/usr/bin/env nextflow

//Creates the `read_pairs` channel that emits for each read-pair a tuple containing
//three elements: the pair ID, the first read-pair file and the second read-pair file

Channel
    .fromFilePairs( params.reads )
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .set { mash_input }

//Parsing the input parameters

ref_database = file( params.mashscreen_database )
adapters_file = file( params.adapters )

//process 1: Mash screen sample read files for pure isolates

process assess_decontamination {
    validExitStatus 0,2
    tag { pair_id }
    publishDir "${params.output_dir}/mash.screen", mode: 'copy'

    input:
    set pair_id, file(reads) from mash_input

    output:
    set pair_id, file(reads), file("${pair_id}.screening_results.txt") into bbduk_input
    file("${pair_id}.mash_screen.tsv")

    script:
    """
    mash screen -w -p 8 ${ref_database} ${reads[0]} ${reads[1]} > ${pair_id}.mash_screen.tsv
    assess_mash_screen.py ${pair_id}.mash_screen.tsv -o ${pair_id}.screening_results.txt
    """
 }

//process 2: Adapter and quality trimming

process bbduk {
        errorStrategy {task.exitStatus == 4 ? 'ignore' : 'finish' }
        tag {pair_id}
        publishDir "${params.output_dir}/bbduk", mode: 'copy'

        input:
	set pair_id, file(reads), file(screening_results) from bbduk_input
        file adapters_file

        output:
        set pair_id, file("${pair_id}_{1,2}.trimmed.fastq.gz") into fastqc_input, shovill
        file "${pair_id}.stats.txt"


        script:
        """

	if grep --quiet "PASS" ${screening_results}; then
             bbduk.sh \
             in1=${reads[0]} \
             in2=${reads[1]} \
             ref=${adapters_file} \
             out1=${pair_id}_1.trimmed.fastq.gz \
             out2=${pair_id}_2.trimmed.fastq.gz \
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
             trimpairsevenly
        else
             exit 4
        fi

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
             --kmers 31,33,55,77,99,127 \
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

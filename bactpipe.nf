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
        publishDir "${params.output_dir}/bbduk", mode: 'copy'
        
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

//Step 3 SPAdes
process spades {
        tag {sample_id}
        publishDir "${params.output_dir}/spades", mode: 'copy'

        input:
        set sample_id, file(reads) from spades_input
        
        output:
        set sample_id, file("spades_output/scaffolds.fasta") into spades_result
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
            
        tag {sample_id}
        publishDir "${params.output_dir}/filtered_scaffolds", mode: 'copy'
        
        input:
        set sample_id, file(scaffolds) from spades_result
        
        output:
        set sample_id, file("${sample_id}_covfiltered.fasta") into filtered_channel 
        
        
        """
        FilterAssembly.pl $scaffolds ${sample_id}
        """
}

//Mauve_process

process mauve {
        tag {sample_id}
        publishDir "${params.output_dir}/mauve", mode: 'copy'

        input:
        set sample_id, file(contigs_file) from filtered_channel

        output:
        set sample_id, file("${sample_id}_ordered.fasta") into rename_channel
               
        """
        java -Xmx500m -cp ${params.mauve_path} \
        	org.gel.mauve.contigs.ContigOrderer \
			-output mauve_output \
			-ref ${params.mauve_ref}  \
			-draft $contigs_file
        ln -vs \$(ls -d mauve_output/alignment* | sort -Vr | head -1)/${contigs_file} "${sample_id}_ordered.fasta"        
        """
}

//rename_contigs_for_prokka

process rename {

        tag {sample_id}
        publishDir "${params.output_dir}/renamed_contigs", mode: 'copy'

        input:
        set sample_id, file(rename_contigs) from rename_channel 

        output:
        set sample_id, file("${sample_id}_renamed.fasta") into prokka_channel

        """
        rename_fasta.py --input $rename_contigs \
        --output ${sample_id}_renamed.fasta
	
        """
}

//Annotation with prokka

process prokka {
        
        tag {pair_id}
        publishDir "${params.output_dir}/prokka", mode: 'copy'

        input:
        set sample_id, file(renamed_contigs) from prokka_channel
                   
     
        output:
        set sample_id, file("prokka/${sample_id}*")          

        """
        prokka $renamed_contigs \
              --proteins ${params.prokka_ref} \
              --outdir prokka \
              --prefix ${sample_id}           
        """
}



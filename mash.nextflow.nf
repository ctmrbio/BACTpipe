#!/usr/bin/env nextflow

//Definition of default parameters

params.reads = '*_R{1,2}.fastq.gz'
params.database = "/db/refseq/*.msh" 
params.adapters = "/home/joseph.kirangwa/adapters.fa"

//Parsing the input

ref_database = file( params.database )
adapters_file = file( params.adapters )

Channel
    .fromFilePairs( params.reads )
    .ifEmpty { error "Cannot find any reads matching: ${params.reads}" }
    .set { mash_input }



//define mash proces

process assess_mash_screen {
    validExitStatus 0,2
    tag { pair_id } 
    publishDir "./mash.screen", mode: 'copy'

    input:
    set pair_id, file(reads) from mash_input

    output:
    set pair_id, file(reads), file("${pair_id}.screening_results.txt") into bbduk_input
    file("${pair_id}.mash_screen.tsv")

    script:

    """
    mash screen -w -p 8 ${ref_database[0]} ${reads[0]} ${reads[1]} > ${pair_id}.mash_screen.tsv
    python /home/joseph.kirangwa/mash-script/mash_scripts/assess_mash_screen.py ${pair_id}.mash_screen.tsv -o ${pair_id}.screening_results.txt
 
    """

 }

//process 3: Adapter and quality trimming

process bbduk {
        errorStrategy {task.exitStatus == 4 ? 'ignore' : 'finish' } 
        tag {pair_id}
        publishDir "./bbduk", mode: 'copy'

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


workflow.onComplete {
        println ( workflow.success ? "Done!" : "Oops .. something went wrong" )
}

        

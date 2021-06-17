run_stub:
	bash ./test_data/mock_data/generate_mock_data.sh && nextflow run main.nf -stub --reads "test_data/mock_data/*_{R1,R2}.fastq.gz"


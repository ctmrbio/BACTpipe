run_stub:
	bash ./test_data/mock_data/generate_mock_data.sh && nextflow run bactpipe.nf -stub --reads "test_data/mock_data/*_{R1,R2}.fastq.gz" --kraken2_db test_data/mock_data/mock_kraken_db_dir

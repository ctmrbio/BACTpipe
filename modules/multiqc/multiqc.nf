
process MULTIQC {
    publishDir "${params.output_dir}/multiqc", mode: 'copy'

    input:
    path('*.json')
    path('*_prokka')

    output:
    path('multiqc_report.html')

    script:
    """
    multiqc . --filename multiqc_report.html
    """

    stub:
    """
    touch multiqc_report.html
    """
}

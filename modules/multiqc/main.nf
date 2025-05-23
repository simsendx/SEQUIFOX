process MULTIQC {
    label 'process_medium'
    
    container 'quay.io/biocontainers/multiqc:1.25.1--pyhdfd78af_0'

    publishDir "${params.outdir}/${workflow.runName}/reports/", mode: params.publish_dir_mode, pattern: "*.html"

    input:
    path  multiqc_files, stageAs: "?/*"
        
    output:
    path "*multiqc_report.html", emit: report

    script:
    """
    # Run multiqc
    multiqc \\
        --force \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
    multiqc: \$( multiqc --version | sed -e "s/multiqc, version //g" )
    END_VERSIONS
    """
}
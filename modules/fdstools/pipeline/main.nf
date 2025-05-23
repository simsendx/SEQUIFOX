process FDSTOOLS_PIPELINE {
    tag "$meta.id"
    label 'process_single'

    container 'quay.io/sfilges/fdstools:2.1.1'

    publishDir "${params.outdir}/${workflow.runName}/fdstools/post_umi/${meta.id}", mode: params.publish_dir_mode, pattern: "*"

    input:
    tuple val(meta), path(reads)
    tuple val(meta2), path(ini_file)
    tuple val(meta3), path(library_file)

    output:
    tuple val(meta), path("pipeline_results") , emit: data_out
    tuple val(meta), path('*stats.txt')       , emit: stats
    tuple val(meta), path('*.html')           , emit: html
    tuple val(meta), path('*.csv')            , emit: csv
    path "versions.yml"                       , emit: versions

    script:

    """
    fdstools pipeline \\
        $ini_file \\
        -l $library_file \\
        -s $reads

    TSSV_VERSION=\$(fdstools pipeline -v | awk '{print \$2}')
    FDSTOOLS_VERSION=\$(fdstools pipeline -v | sed -n 's/.*(part of fdstools \\(.*\\))/\\1/p')

    cat <<-END_VERSIONS > versions.yml
    ${task.process}:
        tssv: \$TSSV_VERSION
        fdstools: \$FDSTOOLS_VERSION
    END_VERSIONS
    """
}
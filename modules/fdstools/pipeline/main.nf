process FDSTOOLS_PIPELINE {
    tag "$meta.id"
    label 'process_single'

    publishDir = [
        path: {"${params.outdir}/${workflow.runName}/fdstools/${meta.id}"},
        mode: params.publish_dir_mode,
        pattern: "*"
    ]

    input:
    tuple val(meta), path(reads)
    tuple val(meta2), path(ini_file)
    tuple val(meta3), path(library_file)

    output:
    tuple val(meta), path("pipeline_results"), emit: data_out
    tuple val(meta), path('*stats.txt')      , emit: stats
    tuple val(meta), path('*.html')          , emit: html
    tuple val(meta), path('*.csv')           , emit: csv

    script:

    """
    fdstools pipeline \\
        $ini_file \\
        -l $library_file \\
        -s $reads
    """
}
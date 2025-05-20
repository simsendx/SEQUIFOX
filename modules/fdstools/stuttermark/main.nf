process FDSTOOLS_STUTTERMARK {
    tag "$meta.id"
    label 'process_single'

    publishDir = [
        path: {"${params.outdir}/${workflow.runName}/fdstools/${meta.id}"},
        mode: params.publish_dir_mode,
        pattern: "*_stutter.csv"
    ]

    input:
    tuple val(meta), path(infile)
    tuple val(meta2), path(library_file)

    output:
    tuple val(meta), path("*_stutter.csv"), emit: stuttermark

    script:
    """
    fdstools stuttermark \\
        -i $infile \\
        -o ${meta.id}_stutter.csv \\
        -l $library_file
    """
}
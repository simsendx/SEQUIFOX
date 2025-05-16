process FDSTOOLS_PIPELINE {
    tag "$meta.id"
    label 'process_single'

    container ''

    input:
    tuple val(meta), path(reads)
    path library_file

    output:
    tuple val(meta), path(data_out), emit: data_out

    script:

    """
    fdstools pipeline \\
        --dir $outpath \\
        --indel-score 2 \\
        --mismatches 0.1 \\
        --num-threads $task.cpus \\
        $library_file \\
        $reads
    """


}
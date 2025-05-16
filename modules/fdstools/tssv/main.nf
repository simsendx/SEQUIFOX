process FDSTOOLS_TSSV {
    tag "$meta.id"
    label 'process_single'

    container 'localhost/fdstools:2.1.1'

    input:
    tuple val(meta), path(reads)
    path library_file
    val indel_score
    val mismatches

    output:
    tuple val(meta), path(data_out), emit: data_out

    script:
    def args = task.ext.args ?: ''
    // TODO Add default arguments for indel_score and mismatches
    """
    fdstools tssv \\
        $args \\
        --num-threads $task.cpus \\
        --dir $outpath \\
        --indel-score $indel_score \\
        --mismatches $mismatches \\
        $library_file \\
        $reads
    """


}
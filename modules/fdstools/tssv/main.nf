process FDSTOOLS_TSSV {
    tag "$meta.id"
    label 'process_single'

    cpus 1

    publishDir = [
        path: {"${params.outdir}/${workflow.runName}/alignment/tssv/${meta.id}"},
        mode: params.publish_dir_mode,
        pattern: "*"
    ]

    input:
    tuple val(meta), path(reads)
    path library_file
    val indel_score
    val mismatches

    output:
    tuple val(meta), path("tssv_out"), emit: tssv_out

    script:
    def args = task.ext.args ?: ''
    """
    fdstools tssv \\
        $args \\
        --num-threads $task.cpus \\
        --dir tssv_out \\
        --indel-score $indel_score \\
        --mismatches $mismatches \\
        --minimum 2 \\
        $library_file \\
        $reads > tssv.out 2>&1
    """


}
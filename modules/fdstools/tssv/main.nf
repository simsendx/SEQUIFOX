process FDSTOOLS_TSSV {
    tag "$meta.id"
    label 'process_single'

    cpus 1

    publishDir = [
        path: {"${params.outdir}/${workflow.runName}/fdstools/${meta.id}/"},
        mode: params.publish_dir_mode,
        pattern: "*"
    ]

    input:
    tuple val(meta), path(reads)
    path library_file
    val indel_score
    val mismatches

    output:
    tuple val(meta), path("tssv_pre_umi"), emit: tssv_pre_umi

    script:
    def args = task.ext.args ?: ''
    """
    mkdir tssv_pre_umi

    fdstools tssv \\
        --num-threads $task.cpus \\
        --dir tssv_pre_umi \\
        --indel-score $indel_score \\
        --mismatches $mismatches \\
        --minimum 2 \\
        --report preumi.html \\
        $library_file \\
        $reads
    """
}
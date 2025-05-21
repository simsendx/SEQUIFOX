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
    tuple val(meta2), path(library_file)
    val indel_score
    val mismatches

    output:
    tuple val(meta), path("tssv_out"), emit: tssv_out
    tuple val(meta), path("tssv_out/*/paired.fq.gz"), emit: paired_fq

    script:
    def args = task.ext.args ?: ''
    """
    mkdir tssv_out

    fdstools tssv \\
        --num-threads $task.cpus \\
        --dir tssv_out \\
        --indel-score $indel_score \\
        --mismatches $mismatches \\
        --minimum 2 \\
        --report preumi.html \\
        $library_file \\
        $reads
    """
}
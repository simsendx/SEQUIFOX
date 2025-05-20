process UMIERRORCORRECT_UMIERRORCORRECT {
    tag "$meta.id"

    cpus 4

    publishDir = [
        path: {"${params.outdir}/${workflow.runName}/out/${meta.id}"},
        mode: params.publish_dir_mode,
        pattern: "*"
    ]

    input:
    tuple val(meta), path(bam)
    path bed_file
    path ref_genome
    val consensus_method

    output:
    tuple val(meta), path("umi_out"), emit: umi_out

    script:
    """
    umi_error_correct.py \\
        -o umi_out \\
        -b $bam \\
        -bed $bed_file \\
        -r $ref_genome \\
        -c $consensus_method \\
        -s ${meta.id} \\
        -t $task.cpus
    """
}